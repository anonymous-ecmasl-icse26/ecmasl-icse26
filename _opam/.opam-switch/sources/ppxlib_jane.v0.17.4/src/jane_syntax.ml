(*_ This file is manually imported from the Jane Street version of the
   OCaml compiler. Don't make changes directly to this file. *)
[@@@ocaml.warning "-missing-record-field-pattern"]

open! Shadow_compiler_distribution
open Asttypes
open Jane_asttypes
open Parsetree
open Jane_syntax_parsing

(** We carefully regulate which bindings we import from [Language_extension]
    to ensure that we can import this file into the Jane Street internal
    repo with no changes.
*)
module Language_extension = struct
  include Language_extension_kernel

  include (
    Language_extension : Language_extension_kernel.Language_extension_for_jane_syntax)
end

(* Suppress the unused module warning so it's easy to keep around the
   shadowing even if we delete use sites of the module. *)
module _ = Language_extension

(****************************************)
(* Helpers used just within this module *)

module type Extension = sig
  val feature : Feature.t
end

module Ast_of (AST : AST) (Ext : Extension) : sig
  (* Wrap a bit of AST with a jane-syntax annotation *)
  val wrap_jane_syntax
    :  string list
    -> (* these strings describe the bit of new syntax *)
       ?payload:payload
    -> AST.ast
    -> AST.ast
end = struct
  let wrap_jane_syntax suffixes ?payload to_be_wrapped =
    AST.make_jane_syntax Ext.feature suffixes ?payload to_be_wrapped
  ;;
end

module Of_ast (Ext : Extension) : sig
  type unwrapped := string list * payload * attributes

  (* The same as [unwrap_jane_syntax_attributes], except throwing
     an exception instead of returning an error.
  *)
  val unwrap_jane_syntax_attributes_exn : loc:Location.t -> attributes -> unwrapped
end = struct
  let extension_string = Feature.extension_component Ext.feature

  module Desugaring_error = struct
    type error =
      | Not_this_embedding of Embedded_name.t
      | Non_embedding

    let report_error ~loc = function
      | Not_this_embedding name ->
        Location.errorf
          ~loc
          "Tried to desugar the embedded term %a@ as belonging to the %s extension"
          Embedded_name.pp_quoted_name
          name
          extension_string
      | Non_embedding ->
        Location.errorf
          ~loc
          "Tried to desugar a non-embedded expression@ as belonging to the %s extension"
          extension_string
    ;;

    exception Error of Location.t * error

    let () =
      Location.register_error_of_exn (function
        | Error (loc, err) -> Some (report_error ~loc err)
        | _ -> None)
    ;;

    let raise ~loc err = raise (Error (loc, err))
  end

  let unwrap_jane_syntax_attributes attrs : (_, Desugaring_error.error) result =
    match find_and_remove_jane_syntax_attribute attrs with
    | Some (ext_name, _loc, payload, attrs) ->
      (match Jane_syntax_parsing.Embedded_name.components ext_name with
       | extension_occur :: names when String.equal extension_occur extension_string ->
         Ok (names, payload, attrs)
       | _ -> Error (Not_this_embedding ext_name))
    | None -> Error Non_embedding
  ;;

  let unwrap_jane_syntax_attributes_exn ~loc attrs =
    match unwrap_jane_syntax_attributes attrs with
    | Ok x -> x
    | Error error -> Desugaring_error.raise ~loc error
  ;;
end

(******************************************************************************)
(** Individual language extension modules *)

(* Note [Check for immutable extension in comprehensions code]
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   When we spot a comprehension for an immutable array, we need to make sure
   that both [comprehensions] and [immutable_arrays] are enabled.  But our
   general mechanism for checking for enabled extensions (in [of_ast]) won't
   work well here: it triggers when converting from
   e.g. [[%jane.non_erasable.comprehensions.array] ...] to the
   comprehensions-specific AST. But if we spot a
   [[%jane.non_erasable.comprehensions.immutable]], there is no expression to
   translate. So we just check for the immutable arrays extension when
   processing a comprehension expression for an immutable array.

   Note [Wrapping with make_entire_jane_syntax]
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   The topmost node in the encoded AST must always look like e.g.
   [%jane.non_erasable.comprehensions]. (More generally,
   [%jane.ERASABILITY.FEATURE] or [@jane.ERASABILITY.FEATURE].) This allows the
   decoding machinery to know what extension is being used and what function to
   call to do the decoding. Accordingly, during encoding, after doing the hard
   work of converting the extension syntax tree into e.g. Parsetree.expression,
   we need to make a final step of wrapping the result in a [%jane.*.xyz] node.
   Ideally, this step would be done by part of our general structure, like we
   separate [of_ast] and [of_ast_internal] in the decode structure; this design
   would make it structurally impossible/hard to forget taking this final step.

   However, the final step is only one line of code (a call to
   [make_entire_jane_syntax]), but yet the name of the feature varies, as does
   the type of the payload. It would thus take several lines of code to execute
   this command otherwise, along with dozens of lines to create the structure in
   the first place. And so instead we just manually call
   [make_entire_jane_syntax] and refer to this Note as a reminder to authors of
   future syntax features to remember to do this wrapping.

   Note [Outer attributes at end]
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   The order of attributes matters for several reasons:
   - If the user writes attributes on a Jane Street OCaml construct, where
     should those appear with respect to the Jane Syntax attribute that
     introduces the construct?
   - Some Jane Syntax embeddings use attributes, and sometimes an AST node will
     have multiple Jane Syntax-related attributes on it. Which attribute should
     Jane Syntax interpret first?

   Both of these questions are settled by a convention where attributes
   appearing later in an attribute list are considered to be "outer" to
   attributes appearing earlier. (ppxlib adopted this convention, and thus we
   need to as well for compatibility.)

   - User-written attributes appear later in the attribute list than
     a Jane Syntax attribute that introduces a syntactic construct.
   - If multiple Jane Syntax attributes appear on an AST node, the ones
     appearing later in the attribute list should be interpreted first.
*)

module type Payload_protocol = sig
  type t

  module Encode : sig
    val as_payload : t loc -> payload
    val list_as_payload : t loc list -> payload
    val option_list_as_payload : t loc option list -> payload
  end

  module Decode : sig
    val from_payload : loc:Location.t -> payload -> t loc
    val list_from_payload : loc:Location.t -> payload -> t loc list
    val option_list_from_payload : loc:Location.t -> payload -> t loc option list
  end
end

module type Stringable = sig
  type t

  val of_string : string -> t option
  val to_string : t -> string

  (** For error messages: a name that can be used to identify the
      [t] being converted to and from string, and its indefinite
      article (either "a" or "an").
  *)
  val indefinite_article_and_name : string * string
end

module Make_payload_protocol_of_stringable (Stringable : Stringable) :
  Payload_protocol with type t := Stringable.t = struct
  module Encode = struct
    let as_expr t_loc =
      let string = Stringable.to_string t_loc.txt in
      Ast_helper.Exp.ident (Location.mkloc (Astlib.Longident.Lident string) t_loc.loc)
    ;;

    let structure_item_of_expr expr =
      { pstr_desc = Pstr_eval (expr, []); pstr_loc = Location.none }
    ;;

    let structure_item_of_none =
      { pstr_desc =
          Pstr_attribute
            { attr_name = Location.mknoloc "jane.none"
            ; attr_payload = PStr []
            ; attr_loc = Location.none
            }
      ; pstr_loc = Location.none
      }
    ;;

    let as_payload t_loc =
      let expr = as_expr t_loc in
      PStr [ structure_item_of_expr expr ]
    ;;

    let list_as_payload t_locs =
      let items = List.map (fun t_loc -> structure_item_of_expr (as_expr t_loc)) t_locs in
      PStr items
    ;;

    let option_list_as_payload t_locs =
      let items =
        List.map
          (function
           | None -> structure_item_of_none
           | Some t_loc -> structure_item_of_expr (as_expr t_loc))
          t_locs
      in
      PStr items
    ;;
  end

  module Desugaring_error = struct
    type error = Unknown_payload of payload

    let report_error ~loc = function
      | Unknown_payload payload ->
        let indefinite_article, name = Stringable.indefinite_article_and_name in
        Location.errorf
          ~loc
          "Attribute payload does not name %s %s:@;%a"
          indefinite_article
          name
          (Printast.payload 0)
          payload
    ;;

    exception Error of Location.t * error

    let () =
      Location.register_error_of_exn (function
        | Error (loc, err) -> Some (report_error ~loc err)
        | _ -> None)
    ;;

    let raise ~loc err = raise (Error (loc, err))
  end

  module Decode = struct
    (* Avoid exporting a definition that raises [Unexpected]. *)
    open struct
      exception Unexpected

      let from_expr = function
        | { pexp_desc = Pexp_ident payload_lid; _ } ->
          let t =
            match Stringable.of_string (Ppxlib.Longident.last_exn payload_lid.txt) with
            | None -> raise Unexpected
            | Some t -> t
          in
          Location.mkloc t payload_lid.loc
        | _ -> raise Unexpected
      ;;

      let expr_of_structure_item = function
        | { pstr_desc = Pstr_eval (expr, _) } -> expr
        | _ -> raise Unexpected
      ;;

      let is_none_structure_item = function
        | { pstr_desc = Pstr_attribute { attr_name = { txt = "jane.none" } } } -> true
        | _ -> false
      ;;

      let from_payload payload =
        match payload with
        | PStr [ item ] -> from_expr (expr_of_structure_item item)
        | _ -> raise Unexpected
      ;;

      let list_from_payload payload =
        match payload with
        | PStr items ->
          List.map (fun item -> from_expr (expr_of_structure_item item)) items
        | _ -> raise Unexpected
      ;;

      let option_list_from_payload payload =
        match payload with
        | PStr items ->
          List.map
            (fun item ->
              if is_none_structure_item item
              then None
              else Some (from_expr (expr_of_structure_item item)))
            items
        | _ -> raise Unexpected
      ;;
    end

    let from_payload ~loc payload : _ loc =
      try from_payload payload with
      | Unexpected -> Desugaring_error.raise ~loc (Unknown_payload payload)
    ;;

    let list_from_payload ~loc payload : _ list =
      try list_from_payload payload with
      | Unexpected -> Desugaring_error.raise ~loc (Unknown_payload payload)
    ;;

    let option_list_from_payload ~loc payload : _ list =
      try option_list_from_payload payload with
      | Unexpected -> Desugaring_error.raise ~loc (Unknown_payload payload)
    ;;
  end
end

module Stringable_const_jkind = struct
  type t = const_jkind

  let indefinite_article_and_name = "a", "layout"
  let to_string = jkind_to_string
  let of_string t = Some (jkind_of_string t)
end

module Jkinds_pprint = struct
  let const_jkind fmt cl =
    Format_doc.fprintf fmt "%s" (Stringable_const_jkind.to_string cl)
  ;;

  let jkind_annotation fmt ann = const_jkind fmt ann.txt
end

(** Jkind annotations' encoding as attribute payload, used in both n-ary
    functions and jkinds. *)
module Jkind_annotation : sig
  include Payload_protocol with type t := const_jkind

  module Decode : sig
    include module type of Decode

    val bound_vars_from_vars_and_payload
      :  loc:Location.t
      -> string Location.loc list
      -> payload
      -> (string Location.loc * jkind_annotation option) list
  end
end = struct
  module Protocol = Make_payload_protocol_of_stringable (Stringable_const_jkind)

  (*******************************************************)
  (* Conversions with a payload *)

  module Encode = Protocol.Encode

  module Decode = struct
    include Protocol.Decode

    module Desugaring_error = struct
      type error = Wrong_number_of_jkinds of int * jkind_annotation option list

      let report_error ~loc = function
        | Wrong_number_of_jkinds (n, jkinds) ->
          Location.errorf
            ~loc
            "Wrong number of layouts in an layout attribute;@;\
             expecting %i but got this list:@;\
             %a"
            n
            (Format_doc.pp_print_list
               (Format_doc.pp_print_option
                  ~none:(fun ppf () -> Format_doc.fprintf ppf "None")
                  Jkinds_pprint.jkind_annotation))
            jkinds
      ;;

      exception Error of Location.t * error

      let () =
        Location.register_error_of_exn (function
          | Error (loc, err) -> Some (report_error ~loc err)
          | _ -> None)
      ;;

      let raise ~loc err = raise (Error (loc, err))
    end

    let bound_vars_from_vars_and_payload ~loc var_names payload =
      let jkinds = option_list_from_payload ~loc payload in
      try List.combine var_names jkinds with
      (* seems silly to check the length in advance when [combine] does *)
      | Invalid_argument _ ->
        Desugaring_error.raise
          ~loc
          (Wrong_number_of_jkinds (List.length var_names, jkinds))
    ;;
  end
end

module Mode_expr = struct
  module Const : sig
    type raw = string
    type t = private raw Location.loc

    val mk : string -> Location.t -> t
    val list_as_payload : t list -> payload
    val list_from_payload : loc:Location.t -> payload -> t list
    val ghostify : t -> t
  end = struct
    type raw = string

    module Protocol = Make_payload_protocol_of_stringable (struct
      type t = raw

      let indefinite_article_and_name = "a", "mode"
      let to_string s = s

      (* Ideally, we should check that [s] consists of only alphabet and numbers.
         However, this func *)

      let of_string' s = s
      let of_string s = Some (of_string' s)
    end)

    let list_as_payload = Protocol.Encode.list_as_payload
    let list_from_payload = Protocol.Decode.list_from_payload

    type t = raw Location.loc

    let mk txt loc : t = { txt; loc }

    let ghostify { txt; loc } =
      let loc = { loc with loc_ghost = true } in
      { txt; loc }
    ;;
  end

  type t = Const.t list Location.loc

  let empty = Location.mknoloc []

  let singleton const =
    let const' = (const : Const.t :> _ Location.loc) in
    Location.mkloc [ const ] const'.loc
  ;;

  let feature : Feature.t = Language_extension Mode
  let attribute_components = []
  let extension_components = []

  let attribute_name =
    Embedded_name.of_feature feature attribute_components |> Embedded_name.to_string
  ;;

  let extension_name =
    Embedded_name.of_feature feature extension_components |> Embedded_name.to_string
  ;;

  let payload_of { txt; _ } =
    match txt with
    | [] -> None
    | _ :: _ as txt -> Some (Const.list_as_payload txt)
  ;;

  let of_payload ~loc payload =
    let l = Const.list_from_payload ~loc payload in
    match l with
    | [] -> Misc.fatal_error "Payload encoding empty mode expression"
    | _ :: _ -> Location.mkloc l loc
  ;;

  let extract_attr attrs =
    let attrs, rest =
      List.partition (fun { attr_name; _ } -> attr_name.txt = attribute_name) attrs
    in
    match attrs with
    | [] -> None, rest
    | [ attr ] -> Some attr, rest
    | _ :: _ :: _ -> Misc.fatal_error "More than one mode attribute"
  ;;

  let of_attr { attr_payload; attr_loc; _ } = of_payload ~loc:attr_loc attr_payload

  let maybe_of_attrs attrs =
    let attr, rest = extract_attr attrs in
    let mode = Option.map of_attr attr in
    mode, rest
  ;;

  let of_attrs attrs =
    let mode, rest = maybe_of_attrs attrs in
    let mode = Option.value mode ~default:empty in
    mode, rest
  ;;

  let attr_of modes =
    match payload_of modes with
    | None -> None
    | Some attr_payload ->
      let attr_name = Location.mknoloc attribute_name in
      let attr_loc = modes.loc in
      Some { attr_name; attr_loc; attr_payload }
  ;;

  let ghostify { txt; loc } =
    let loc = { loc with loc_ghost = true } in
    let txt = List.map Const.ghostify txt in
    { loc; txt }
  ;;
end

(** List and array comprehensions *)
module Comprehensions = struct
  module Ext = struct
    let feature : Feature.t = Language_extension Comprehensions
  end

  module Ast_of = Ast_of (Expression) (Ext)
  module Of_ast = Of_ast (Ext)
  include Ext

  type iterator =
    | Range of
        { start : expression
        ; stop : expression
        ; direction : direction_flag
        }
    | In of expression

  type clause_binding =
    { pattern : pattern
    ; iterator : iterator
    ; attributes : attribute list
    }

  type clause =
    | For of clause_binding list
    | When of expression

  type comprehension =
    { body : expression
    ; clauses : clause list
    }

  type expression =
    | Cexp_list_comprehension of comprehension
    | Cexp_array_comprehension of mutable_flag * comprehension

  (* The desugared-to-OCaml version of comprehensions is described by the
     following BNF, where [{% '...' | expr %}] refers to the result of
     [Expression.make_jane_syntax] (via [comprehension_expr]) as described at
     the top of [jane_syntax_parsing.mli].

     {v
         comprehension ::=
           | {% 'comprehension.list' | '[' clauses ']' %}
           | {% 'comprehension.array' | '[|' clauses '|]' %}

         clauses ::=
           | {% 'comprehension.for' | 'let' iterator+ 'in' clauses %}
           | {% 'comprehension.when' | expr ';' clauses %}
           | {% 'comprehension.body' | expr %}

         iterator ::=
           | pattern '=' {% 'comprehension.for.range.upto' | expr ',' expr %}
           | pattern '=' {% 'comprehension.for.range.downto' | expr ',' expr %}
           | pattern '=' {% 'comprehension.for.in' | expr %}
     v}
  *)

  (** First, we define how to go from the nice AST to the OCaml AST; this is
      the [expr_of_...] family of expressions, culminating in
      [expr_of_comprehension_expr]. *)

  let expr_of_iterator = function
    | Range { start; stop; direction } ->
      Ast_of.wrap_jane_syntax
        [ "for"
        ; "range"
        ; (match direction with
           | Upto -> "upto"
           | Downto -> "downto")
        ]
        (Ast_helper.Exp.tuple [ start; stop ])
    | In seq -> Ast_of.wrap_jane_syntax [ "for"; "in" ] seq
  ;;

  let expr_of_clause_binding { pattern; iterator; attributes } =
    Ast_helper.Vb.mk ~attrs:attributes pattern (expr_of_iterator iterator)
  ;;

  let expr_of_clause clause rest =
    match clause with
    | For iterators ->
      Ast_of.wrap_jane_syntax
        [ "for" ]
        (Ast_helper.Exp.let_
           Nonrecursive
           (List.map expr_of_clause_binding iterators)
           rest)
    | When cond -> Ast_of.wrap_jane_syntax [ "when" ] (Ast_helper.Exp.sequence cond rest)
  ;;

  let expr_of_comprehension ~type_ { body; clauses } =
    (* We elect to wrap the body in a new AST node (here, [Pexp_lazy])
       because it makes it so there is no AST node that can carry multiple Jane
       Syntax-related attributes in addition to user-written attributes. This
       choice simplifies the definition of [comprehension_expr_of_expr], as
       part of its contract is threading through the user-written attributes
       on the outermost node.
    *)
    Ast_of.wrap_jane_syntax
      type_
      (Ast_helper.Exp.lazy_
         (List.fold_right
            expr_of_clause
            clauses
            (Ast_of.wrap_jane_syntax [ "body" ] body)))
  ;;

  let expr_of ~loc cexpr =
    (* See Note [Wrapping with make_entire_jane_syntax] *)
    Expression.make_entire_jane_syntax ~loc feature (fun () ->
      match cexpr with
      | Cexp_list_comprehension comp -> expr_of_comprehension ~type_:[ "list" ] comp
      | Cexp_array_comprehension (amut, comp) ->
        expr_of_comprehension
          ~type_:
            [ "array"
            ; (match amut with
               | Mutable -> "mutable"
               | Immutable -> "immutable")
            ]
          comp)
  ;;

  (** Then, we define how to go from the OCaml AST to the nice AST; this is
      the [..._of_expr] family of expressions, culminating in
      [comprehension_expr_of_expr]. *)

  module Desugaring_error = struct
    type error =
      | Has_payload of payload
      | Bad_comprehension_embedding of string list
      | No_clauses

    let report_error ~loc = function
      | Has_payload payload ->
        Location.errorf
          ~loc
          "Comprehensions attribute has an unexpected payload:@;%a"
          (Printast.payload 0)
          payload
      | Bad_comprehension_embedding subparts ->
        Location.errorf
          ~loc
          "Unknown, unexpected, or malformed@ comprehension embedded term %a"
          Embedded_name.pp_quoted_name
          (Embedded_name.of_feature feature subparts)
      | No_clauses ->
        Location.errorf ~loc "Tried to desugar a comprehension with no clauses"
    ;;

    exception Error of Location.t * error

    let () =
      Location.register_error_of_exn (function
        | Error (loc, err) -> Some (report_error ~loc err)
        | _ -> None)
    ;;

    let raise expr err = raise (Error (expr.pexp_loc, err))
  end

  (* Returns the expression node with the outermost Jane Syntax-related
     attribute removed. *)
  let expand_comprehension_extension_expr expr =
    let names, payload, attributes =
      Of_ast.unwrap_jane_syntax_attributes_exn ~loc:expr.pexp_loc expr.pexp_attributes
    in
    match payload with
    | PStr [] -> names, { expr with pexp_attributes = attributes }
    | _ -> Desugaring_error.raise expr (Has_payload payload)
  ;;

  let iterator_of_expr expr =
    match expand_comprehension_extension_expr expr with
    | [ "for"; "range"; "upto" ], { pexp_desc = Pexp_tuple [ start; stop ]; _ } ->
      Range { start; stop; direction = Upto }
    | [ "for"; "range"; "downto" ], { pexp_desc = Pexp_tuple [ start; stop ]; _ } ->
      Range { start; stop; direction = Downto }
    | [ "for"; "in" ], seq -> In seq
    | bad, _ -> Desugaring_error.raise expr (Bad_comprehension_embedding bad)
  ;;

  let clause_binding_of_vb { pvb_pat; pvb_expr; pvb_attributes; pvb_loc = _ } =
    { pattern = pvb_pat
    ; iterator = iterator_of_expr pvb_expr
    ; attributes = pvb_attributes
    }
  ;;

  let add_clause clause comp = { comp with clauses = clause :: comp.clauses }

  let comprehension_of_expr =
    let rec raw_comprehension_of_expr expr =
      match expand_comprehension_extension_expr expr with
      | [ "for" ], { pexp_desc = Pexp_let (Nonrecursive, iterators, rest); _ } ->
        add_clause
          (For (List.map clause_binding_of_vb iterators))
          (raw_comprehension_of_expr rest)
      | [ "when" ], { pexp_desc = Pexp_sequence (cond, rest); _ } ->
        add_clause (When cond) (raw_comprehension_of_expr rest)
      | [ "body" ], body -> { body; clauses = [] }
      | bad, _ -> Desugaring_error.raise expr (Bad_comprehension_embedding bad)
    in
    fun expr ->
      match raw_comprehension_of_expr expr with
      | { body = _; clauses = [] } -> Desugaring_error.raise expr No_clauses
      | comp -> comp
  ;;

  (* Returns remaining unconsumed attributes on outermost expression *)
  let comprehension_expr_of_expr expr =
    let name, wrapper = expand_comprehension_extension_expr expr in
    let comp =
      match name, wrapper.pexp_desc with
      | [ "list" ], Pexp_lazy comp -> Cexp_list_comprehension (comprehension_of_expr comp)
      | [ "array"; "mutable" ], Pexp_lazy comp ->
        Cexp_array_comprehension (Mutable, comprehension_of_expr comp)
      | [ "array"; "immutable" ], Pexp_lazy comp ->
        (* assert_extension_enabled:
           See Note [Check for immutable extension in comprehensions code] *)
        assert_extension_enabled ~loc:expr.pexp_loc Immutable_arrays ();
        Cexp_array_comprehension (Immutable, comprehension_of_expr comp)
      | bad, _ -> Desugaring_error.raise expr (Bad_comprehension_embedding bad)
    in
    comp, wrapper.pexp_attributes
  ;;
end

(** Immutable arrays *)
module Immutable_arrays = struct
  type nonrec expression = Iaexp_immutable_array of expression list
  type nonrec pattern = Iapat_immutable_array of pattern list

  let feature : Feature.t = Language_extension Immutable_arrays

  let expr_of ~loc = function
    | Iaexp_immutable_array elts ->
      (* See Note [Wrapping with make_entire_jane_syntax] *)
      Expression.make_entire_jane_syntax ~loc feature (fun () ->
        Ast_helper.Exp.array elts)
  ;;

  (* Returns remaining unconsumed attributes *)
  let of_expr expr =
    match expr.pexp_desc with
    | Pexp_array elts -> Iaexp_immutable_array elts, expr.pexp_attributes
    | _ -> failwith "Malformed immutable array expression"
  ;;

  let pat_of ~loc = function
    | Iapat_immutable_array elts ->
      (* See Note [Wrapping with make_entire_jane_syntax] *)
      Pattern.make_entire_jane_syntax ~loc feature (fun () -> Ast_helper.Pat.array elts)
  ;;

  (* Returns remaining unconsumed attributes *)
  let of_pat pat =
    match pat.ppat_desc with
    | Ppat_array elts -> Iapat_immutable_array elts, pat.ppat_attributes
    | _ -> failwith "Malformed immutable array pattern"
  ;;
end

module N_ary_functions = struct
  module Ext = struct
    let feature : Feature.t = Builtin
  end

  module Ast_of = Ast_of (Expression) (Ext)
  module Of_ast = Of_ast (Ext)

  type function_param_desc =
    | Pparam_val of arg_label * expression option * pattern
    | Pparam_newtype of string loc * jkind_annotation option

  let function_param_desc_of_parsetree : Parsetree.function_param_desc -> function_param_desc
    = function
    | Pparam_val (lbl, def, pat) -> Pparam_val (lbl, def, pat)
    | Pparam_newtype tv -> Pparam_newtype (tv, None)

  let function_param_desc_to_parsetree : function_param_desc -> Parsetree.function_param_desc
    = function
    | Pparam_val (lbl, def, pat) -> Pparam_val (lbl, def, pat)
    | Pparam_newtype (tv, _jkind) -> Pparam_newtype tv

  type function_param =
    { pparam_desc : function_param_desc
    ; pparam_loc : Location.t
    }

  let function_param_of_parsetree : Parsetree.function_param -> function_param
    = fun pparam ->
      { pparam_desc = function_param_desc_of_parsetree pparam.pparam_desc
      ; pparam_loc = pparam.pparam_loc
      }

  let function_param_to_parsetree : function_param -> Parsetree.function_param
    = fun pparam ->
      { pparam_desc = function_param_desc_to_parsetree pparam.pparam_desc
      ; pparam_loc = pparam.pparam_loc
      }

  type function_constraint =
    { mode_annotations : Mode_expr.t
    ; type_constraint : Parsetree.type_constraint
    }

  let function_constraint_of_parsetree : Parsetree.type_constraint -> function_constraint
    = fun type_constraint ->
      { mode_annotations = Mode_expr.empty
      ; type_constraint
      }

  let function_constraint_to_parsetree : function_constraint -> Parsetree.type_constraint
    = fun constr -> constr.type_constraint

  type expression = function_param list * function_constraint option * function_body

  let of_expr expr =
    match expr.pexp_desc with
    | Pexp_function (params, constr, body) ->
      Some
        (( List.map function_param_of_parsetree params
        , Option.map function_constraint_of_parsetree constr
        , body
        )
      , expr.pexp_attributes)
    | _ -> None

  let expr_of ~loc (params, constraint_, body) =
    let pexp_desc =
      Pexp_function (
        List.map function_param_to_parsetree params,
        Option.map function_constraint_to_parsetree constraint_,
        body
      )
    in
    { pexp_desc; pexp_loc = loc; pexp_loc_stack = []; pexp_attributes = [] }

end

(** Labeled tuples *)
module Labeled_tuples = struct
  module Ext = struct
    let feature : Feature.t = Language_extension Labeled_tuples
  end

  module Of_ast = Of_ast (Ext)
  include Ext

  type nonrec core_type = (string option * core_type) list
  type nonrec expression = (string option * expression) list
  type nonrec pattern = (string option * pattern) list * closed_flag

  let string_of_label = function
    | None -> ""
    | Some lbl -> lbl
  ;;

  let label_of_string = function
    | "" -> None
    | s -> Some s
  ;;

  let string_of_closed_flag = function
    | Closed -> "closed"
    | Open -> "open"
  ;;

  let closed_flag_of_string = function
    | "closed" -> Closed
    | "open" -> Open
    | _ -> failwith "bad closed flag"
  ;;

  module Desugaring_error = struct
    type error =
      | Malformed
      | Has_payload of payload

    let report_error ~loc = function
      | Malformed -> Location.errorf ~loc "Malformed embedded labeled tuple term"
      | Has_payload payload ->
        Location.errorf
          ~loc
          "Labeled tuples attribute has an unexpected payload:@;%a"
          (Printast.payload 0)
          payload
    ;;

    exception Error of Location.t * error

    let () =
      Location.register_error_of_exn (function
        | Error (loc, err) -> Some (report_error ~loc err)
        | _ -> None)
    ;;

    let raise loc err = raise (Error (loc, err))
  end

  let expand_labeled_tuple_extension loc attrs =
    let names, payload, attrs = Of_ast.unwrap_jane_syntax_attributes_exn ~loc attrs in
    match payload with
    | PStr [] -> names, attrs
    | _ -> Desugaring_error.raise loc (Has_payload payload)
  ;;

  type 'a label_check_result =
    | No_labels of 'a list
    | At_least_one_label of (string option * 'a) list

  let check_for_any_label xs =
    if List.for_all (fun (lbl, _x) -> Option.is_none lbl) xs
    then No_labels (List.map snd xs)
    else At_least_one_label xs
  ;;

  let typ_of ~loc tl =
    match check_for_any_label tl with
    | No_labels tl -> Ast_helper.Typ.tuple ~loc tl
    | At_least_one_label tl ->
      (* See Note [Wrapping with make_entire_jane_syntax] *)
      Core_type.make_entire_jane_syntax ~loc feature (fun () ->
        let names = List.map (fun (label, _) -> string_of_label label) tl in
        Core_type.make_jane_syntax feature names @@ Ast_helper.Typ.tuple (List.map snd tl))
  ;;

  (* Returns remaining unconsumed attributes *)
  let of_typ typ =
    let labels, ptyp_attributes =
      expand_labeled_tuple_extension typ.ptyp_loc typ.ptyp_attributes
    in
    match typ.ptyp_desc with
    | Ptyp_tuple components ->
      if List.length labels <> List.length components
      then Desugaring_error.raise typ.ptyp_loc Malformed;
      let labeled_components =
        List.map2 (fun s t -> label_of_string s, t) labels components
      in
      labeled_components, ptyp_attributes
    | _ -> Desugaring_error.raise typ.ptyp_loc Malformed
  ;;

  let expr_of ~loc el =
    match check_for_any_label el with
    | No_labels el -> Ast_helper.Exp.tuple ~loc el
    | At_least_one_label el ->
      (* See Note [Wrapping with make_entire_jane_syntax] *)
      Expression.make_entire_jane_syntax ~loc feature (fun () ->
        let names = List.map (fun (label, _) -> string_of_label label) el in
        Expression.make_jane_syntax feature names
        @@ Ast_helper.Exp.tuple (List.map snd el))
  ;;

  (* Returns remaining unconsumed attributes *)
  let of_expr expr =
    let labels, pexp_attributes =
      expand_labeled_tuple_extension expr.pexp_loc expr.pexp_attributes
    in
    match expr.pexp_desc with
    | Pexp_tuple components ->
      if List.length labels <> List.length components
      then Desugaring_error.raise expr.pexp_loc Malformed;
      let labeled_components =
        List.map2 (fun s e -> label_of_string s, e) labels components
      in
      labeled_components, pexp_attributes
    | _ -> Desugaring_error.raise expr.pexp_loc Malformed
  ;;

  let pat_of =
    let make_jane_syntax ~loc pl closed =
      (* See Note [Wrapping with make_entire_jane_syntax] *)
      Pattern.make_entire_jane_syntax ~loc feature (fun () ->
        let names = List.map (fun (label, _) -> string_of_label label) pl in
        Pattern.make_jane_syntax feature (string_of_closed_flag closed :: names)
        @@ Ast_helper.Pat.tuple (List.map snd pl))
    in
    fun ~loc (pl, closed) ->
      match closed with
      | Open -> make_jane_syntax ~loc pl closed
      | Closed ->
        (match check_for_any_label pl with
         | No_labels pl -> Ast_helper.Pat.tuple ~loc pl
         | At_least_one_label pl -> make_jane_syntax ~loc pl closed)
  ;;

  (* Returns remaining unconsumed attributes *)
  let of_pat pat =
    let labels, ppat_attributes =
      expand_labeled_tuple_extension pat.ppat_loc pat.ppat_attributes
    in
    match labels, pat.ppat_desc with
    | closed :: labels, Ppat_tuple components ->
      if List.length labels <> List.length components
      then Desugaring_error.raise pat.ppat_loc Malformed;
      let closed = closed_flag_of_string closed in
      let labeled_components =
        List.map2 (fun s e -> label_of_string s, e) labels components
      in
      (labeled_components, closed), ppat_attributes
    | _ -> Desugaring_error.raise pat.ppat_loc Malformed
  ;;
end

(** [include functor] *)
module Include_functor = struct
  type signature_item = Ifsig_include_functor of include_description
  type structure_item = Ifstr_include_functor of include_declaration

  let feature : Feature.t = Language_extension Include_functor

  let sig_item_of ~loc = function
    | Ifsig_include_functor incl ->
      (* See Note [Wrapping with make_entire_jane_syntax] *)
      Signature_item.make_entire_jane_syntax ~loc feature (fun () ->
        Ast_helper.Sig.include_ incl)
  ;;

  let of_sig_item sigi =
    match sigi.psig_desc with
    | Psig_include incl -> Ifsig_include_functor incl
    | _ -> failwith "Malformed [include functor] in signature"
  ;;

  let str_item_of ~loc = function
    | Ifstr_include_functor incl ->
      (* See Note [Wrapping with make_entire_jane_syntax] *)
      Structure_item.make_entire_jane_syntax ~loc feature (fun () ->
        Ast_helper.Str.include_ incl)
  ;;

  let of_str_item stri =
    match stri.pstr_desc with
    | Pstr_include incl -> Ifstr_include_functor incl
    | _ -> failwith "Malformed [include functor] in structure"
  ;;
end

(** Module strengthening *)
module Strengthen = struct
  type nonrec module_type =
    { mty : Parsetree.module_type
    ; mod_id : Astlib.Longident.t Location.loc
    }

  let feature : Feature.t = Language_extension Module_strengthening

  (* Encoding: [S with M] becomes [functor (_ : S) -> (module M)], where
     the [(module M)] is a [Pmty_alias].  This isn't syntax we can write, but
     [(module M)] can be the inferred type for [M], so this should be fine. *)

  let mty_of ~loc { mty; mod_id } =
    (* See Note [Wrapping with make_entire_jane_syntax] *)
    Module_type.make_entire_jane_syntax ~loc feature (fun () ->
      Ast_helper.Mty.functor_
        (Named (Location.mknoloc None, mty))
        (Ast_helper.Mty.alias mod_id))
  ;;

  (* Returns remaining unconsumed attributes *)
  let of_mty mty =
    match mty.pmty_desc with
    | Pmty_functor (Named (_, mty), { pmty_desc = Pmty_alias mod_id }) ->
      { mty; mod_id }, mty.pmty_attributes
    | _ -> failwith "Malformed strengthened module type"
  ;;
end

(** Layouts *)
module Layouts = struct
  module Ext = struct
    let feature : Feature.t = Language_extension Layouts
  end

  include Ext
  module Of_ast = Of_ast (Ext)

  type constant =
    | Float of string * char option
    | Integer of string * char

  type nonrec expression =
    | Lexp_constant of constant
    | Lexp_newtype of string loc * jkind_annotation * expression

  type nonrec pattern = Lpat_constant of constant

  type nonrec core_type =
    | Ltyp_var of
        { name : string option
        ; jkind : jkind_annotation
        }
    | Ltyp_poly of
        { bound_vars : (string loc * jkind_annotation option) list
        ; inner_type : core_type
        }
    | Ltyp_alias of
        { aliased_type : core_type
        ; name : string option
        ; jkind : jkind_annotation
        }

  type nonrec extension_constructor =
    | Lext_decl of
        (string Location.loc * jkind_annotation option) list
        * constructor_arguments
        * Parsetree.core_type option

  (*******************************************************)
  (* Pretty-printing *)

  module Pprint = Jkinds_pprint

  (*******************************************************)
  (* Errors *)

  module Desugaring_error = struct
    type error =
      | Unexpected_wrapped_type of Parsetree.core_type
      | Unexpected_wrapped_ext of Parsetree.extension_constructor
      | Unexpected_attribute of string list
      | No_integer_suffix
      | Unexpected_constant of Parsetree.constant
      | Unexpected_wrapped_expr of Parsetree.expression
      | Unexpected_wrapped_pat of Parsetree.pattern

    (* Most things here are unprintable because we can't reference any
       [Printast] functions that aren't exposed by the upstream compiler, as we
       want this file to be compatible with the upstream compiler; see Note
       [Buildable with upstream] in jane_syntax.mli for details. *)
    let report_error ~loc = function
      | Unexpected_wrapped_type _typ ->
        Location.errorf ~loc "Layout attribute on wrong core type"
      | Unexpected_wrapped_ext _ext ->
        Location.errorf ~loc "Layout attribute on wrong extension constructor"
      | Unexpected_attribute names ->
        Location.errorf
          ~loc
          "Layout extension does not understand these attribute names:@;[%a]"
          (Format_doc.pp_print_list
             ~pp_sep:(fun ppf () -> Format_doc.fprintf ppf ";@ ")
             Format_doc.pp_print_text)
          names
      | No_integer_suffix ->
        Location.errorf
          ~loc
          "All unboxed integers require a suffix to determine their size."
      | Unexpected_constant _c -> Location.errorf ~loc "Unexpected unboxed constant"
      | Unexpected_wrapped_expr expr ->
        Location.errorf
          ~loc
          "Layout attribute on wrong expression:@;%a"
          (Printast.expression 0)
          expr
      | Unexpected_wrapped_pat _pat ->
        Location.errorf ~loc "Layout attribute on wrong pattern"
    ;;

    exception Error of Location.t * error

    let () =
      Location.register_error_of_exn (function
        | Error (loc, err) -> Some (report_error ~loc err)
        | _ -> None)
    ;;

    let raise ~loc err = raise (Error (loc, err))
  end

  module Encode = Jkind_annotation.Encode
  module Decode = Jkind_annotation.Decode

  (*******************************************************)
  (* Constants *)

  let constant_of = function
    | Float (x, suffix) -> Pconst_float (x, suffix)
    | Integer (x, suffix) -> Pconst_integer (x, Some suffix)
  ;;

  let of_constant ~loc = function
    | Pconst_float (x, suffix) -> Float (x, suffix)
    | Pconst_integer (x, Some suffix) -> Integer (x, suffix)
    | Pconst_integer (_, None) -> Desugaring_error.raise ~loc No_integer_suffix
    | const -> Desugaring_error.raise ~loc (Unexpected_constant const)
  ;;

  (*******************************************************)
  (* Encoding expressions *)

  let expr_of ~loc expr =
    let module Ast_of = Ast_of (Expression) (Ext) in
    (* See Note [Wrapping with make_entire_jane_syntax] *)
    Expression.make_entire_jane_syntax ~loc feature (fun () ->
      match expr with
      | Lexp_constant c ->
        let constant = constant_of c in
        Ast_of.wrap_jane_syntax [ "unboxed" ] @@ Ast_helper.Exp.constant constant
      | Lexp_newtype (name, jkind, inner_expr) ->
        let payload = Encode.as_payload jkind in
        Ast_of.wrap_jane_syntax [ "newtype" ] ~payload
        @@ Ast_helper.Exp.newtype name inner_expr)
  ;;

  (*******************************************************)
  (* Desugaring expressions *)

  let of_expr expr =
    let loc = expr.pexp_loc in
    let names, payload, attributes =
      Of_ast.unwrap_jane_syntax_attributes_exn ~loc expr.pexp_attributes
    in
    let lexpr =
      match names with
      | [ "unboxed" ] ->
        (match expr.pexp_desc with
         | Pexp_constant const -> Lexp_constant (of_constant ~loc const)
         | _ -> Desugaring_error.raise ~loc (Unexpected_wrapped_expr expr))
      | [ "newtype" ] ->
        let jkind = Decode.from_payload ~loc payload in
        (match expr.pexp_desc with
         | Pexp_newtype (name, inner_expr) -> Lexp_newtype (name, jkind, inner_expr)
         | _ -> Desugaring_error.raise ~loc (Unexpected_wrapped_expr expr))
      | _ -> Desugaring_error.raise ~loc (Unexpected_attribute names)
    in
    lexpr, attributes
  ;;

  (*******************************************************)
  (* Encoding patterns *)

  let pat_of ~loc t =
    Pattern.make_entire_jane_syntax ~loc feature (fun () ->
      match t with
      | Lpat_constant c ->
        let constant = constant_of c in
        Ast_helper.Pat.constant constant)
  ;;

  (*******************************************************)
  (* Desugaring patterns *)

  let of_pat pat =
    let loc = pat.ppat_loc in
    let lpat =
      match pat.ppat_desc with
      | Ppat_constant const -> Lpat_constant (of_constant ~loc const)
      | _ -> Desugaring_error.raise ~loc (Unexpected_wrapped_pat pat)
    in
    lpat, pat.ppat_attributes
  ;;

  (*******************************************************)
  (* Encoding types *)

  module Type_of = Ast_of (Core_type) (Ext)

  let type_of ~loc typ =
    let exception No_wrap_necessary of Parsetree.core_type in
    try
      (* See Note [Wrapping with make_entire_jane_syntax] *)
      Core_type.make_entire_jane_syntax ~loc feature (fun () ->
        match typ with
        | Ltyp_var { name; jkind } ->
          let payload = Encode.as_payload jkind in
          Type_of.wrap_jane_syntax [ "var" ] ~payload
          @@
          (match name with
           | None -> Ast_helper.Typ.any ~loc ()
           | Some name -> Ast_helper.Typ.var ~loc name)
        | Ltyp_poly { bound_vars; inner_type } ->
          let var_names, jkinds = List.split bound_vars in
          (* Pass the loc because we don't want a ghost location here *)
          let tpoly = Ast_helper.Typ.poly ~loc var_names inner_type in
          if List.for_all Option.is_none jkinds
          then raise (No_wrap_necessary tpoly)
          else (
            let payload = Encode.option_list_as_payload jkinds in
            Type_of.wrap_jane_syntax [ "poly" ] ~payload tpoly)
        | Ltyp_alias { aliased_type; name; jkind } ->
          let payload = Encode.as_payload jkind in
          let has_name, inner_typ =
            match name with
            | None -> "anon", aliased_type
            | Some name -> "named", Ast_helper.Typ.alias aliased_type (Location.mkloc name loc)
          in
          Type_of.wrap_jane_syntax [ "alias"; has_name ] ~payload inner_typ)
    with
    | No_wrap_necessary result_type -> result_type
  ;;

  (*******************************************************)
  (* Desugaring types *)

  let of_type typ =
    let loc = typ.ptyp_loc in
    let names, payload, attributes =
      Of_ast.unwrap_jane_syntax_attributes_exn ~loc typ.ptyp_attributes
    in
    let lty =
      match names with
      | [ "var" ] ->
        let jkind = Decode.from_payload ~loc payload in
        (match typ.ptyp_desc with
         | Ptyp_any -> Ltyp_var { name = None; jkind }
         | Ptyp_var name -> Ltyp_var { name = Some name; jkind }
         | _ -> Desugaring_error.raise ~loc (Unexpected_wrapped_type typ))
      | [ "poly" ] ->
        (match typ.ptyp_desc with
         | Ptyp_poly (var_names, inner_type) ->
           let bound_vars =
             Decode.bound_vars_from_vars_and_payload ~loc var_names payload
           in
           Ltyp_poly { bound_vars; inner_type }
         | _ -> Desugaring_error.raise ~loc (Unexpected_wrapped_type typ))
      | [ "alias"; "anon" ] ->
        let jkind = Decode.from_payload ~loc payload in
        Ltyp_alias
          { aliased_type = { typ with ptyp_attributes = attributes }; name = None; jkind }
      | [ "alias"; "named" ] ->
        let jkind = Decode.from_payload ~loc payload in
        (match typ.ptyp_desc with
         | Ptyp_alias (inner_typ, name) ->
           Ltyp_alias { aliased_type = inner_typ; name = Some name.txt; jkind }
         | _ -> Desugaring_error.raise ~loc (Unexpected_wrapped_type typ))
      | _ -> Desugaring_error.raise ~loc (Unexpected_attribute names)
    in
    lty, attributes
  ;;

  (*******************************************************)
  (* Encoding extension constructor *)

  module Ext_ctor_of = Ast_of (Extension_constructor) (Ext)

  let extension_constructor_of ~loc ~name ?info ?docs ext =
    (* using optional parameters to hook into existing defaulting
       in [Ast_helper.Te.decl], which seems unwise to duplicate *)
    let exception No_wrap_necessary of Parsetree.extension_constructor in
    try
      (* See Note [Wrapping with make_entire_jane_syntax] *)
      Extension_constructor.make_entire_jane_syntax ~loc feature (fun () ->
        match ext with
        | Lext_decl (bound_vars, args, res) ->
          let vars, jkinds = List.split bound_vars in
          let ext_ctor =
            (* Pass ~loc here, because the constructor declaration is
                 not a ghost *)
            Ast_helper.Te.decl ~loc ~vars ~args ?info ?docs ?res name
          in
          if List.for_all Option.is_none jkinds
          then raise (No_wrap_necessary ext_ctor)
          else (
            let payload = Encode.option_list_as_payload jkinds in
            Ext_ctor_of.wrap_jane_syntax [ "ext" ] ~payload ext_ctor))
    with
    | No_wrap_necessary ext_ctor -> ext_ctor
  ;;

  (*******************************************************)
  (* Desugaring extension constructor *)

  let of_extension_constructor ext =
    let loc = ext.pext_loc in
    let names, payload, attributes =
      Of_ast.unwrap_jane_syntax_attributes_exn ~loc ext.pext_attributes
    in
    let lext =
      match names with
      | [ "ext" ] ->
        (match ext.pext_kind with
         | Pext_decl (var_names, args, res) ->
           let bound_vars =
             Decode.bound_vars_from_vars_and_payload ~loc var_names payload
           in
           Lext_decl (bound_vars, args, res)
         | _ -> Desugaring_error.raise ~loc (Unexpected_wrapped_ext ext))
      | _ -> Desugaring_error.raise ~loc (Unexpected_attribute names)
    in
    lext, attributes
  ;;

  (*********************************************************)
  (* Constructing a [constructor_declaration] with jkinds *)

  module Ctor_decl_of = Ast_of (Constructor_declaration) (Ext)

  let constructor_declaration_of ~loc ~attrs ~info ~vars_jkinds ~args ~res name =
    let vars, jkinds = List.split vars_jkinds in
    let ctor_decl = Ast_helper.Type.constructor ~loc ~info ~vars ~args ?res name in
    let ctor_decl =
      if List.for_all Option.is_none jkinds
      then ctor_decl
      else (
        let payload = Encode.option_list_as_payload jkinds in
        Constructor_declaration.make_entire_jane_syntax ~loc feature (fun () ->
          Ctor_decl_of.wrap_jane_syntax [ "vars" ] ~payload ctor_decl))
    in
    (* Performance hack: save an allocation if [attrs] is empty. *)
    match attrs with
    | [] -> ctor_decl
    | _ :: _ as attrs ->
      (* See Note [Outer attributes at end] *)
      { ctor_decl with pcd_attributes = ctor_decl.pcd_attributes @ attrs }
  ;;

  let of_constructor_declaration_internal (feat : Feature.t) ctor_decl =
    match feat with
    | Language_extension Layouts ->
      let loc = ctor_decl.pcd_loc in
      let names, payload, attributes =
        Of_ast.unwrap_jane_syntax_attributes_exn ~loc ctor_decl.pcd_attributes
      in
      let vars_jkinds =
        match names with
        | [ "vars" ] ->
          Decode.bound_vars_from_vars_and_payload ~loc ctor_decl.pcd_vars payload
        | _ -> Desugaring_error.raise ~loc (Unexpected_attribute names)
      in
      Some (vars_jkinds, attributes)
    | _ -> None
  ;;

  let of_constructor_declaration =
    Constructor_declaration.make_of_ast
      ~of_ast_internal:of_constructor_declaration_internal
  ;;

  (*********************************************************)
  (* Constructing a [type_declaration] with jkinds *)

  module Type_decl_of = Ast_of (Type_declaration) (Ext)

  let type_declaration_of
    ~loc
    ~attrs
    ~docs
    ~text
    ~params
    ~cstrs
    ~kind
    ~priv
    ~manifest
    ~jkind
    name
    =
    let type_decl =
      Ast_helper.Type.mk ~loc ~docs ?text ~params ~cstrs ~kind ~priv ?manifest name
    in
    let type_decl =
      match jkind with
      | None -> type_decl
      | Some jkind ->
        Type_declaration.make_entire_jane_syntax ~loc feature (fun () ->
          let payload = Encode.as_payload jkind in
          Type_decl_of.wrap_jane_syntax [ "annot" ] ~payload type_decl)
    in
    (* Performance hack: save an allocation if [attrs] is empty. *)
    match attrs with
    | [] -> type_decl
    | _ :: _ as attrs ->
      (* See Note [Outer attributes at end] *)
      { type_decl with ptype_attributes = type_decl.ptype_attributes @ attrs }
  ;;

  let of_type_declaration_internal (feat : Feature.t) type_decl =
    match feat with
    | Language_extension Layouts ->
      let loc = type_decl.ptype_loc in
      let names, payload, attributes =
        Of_ast.unwrap_jane_syntax_attributes_exn ~loc type_decl.ptype_attributes
      in
      let jkind_annot =
        match names with
        | [ "annot" ] -> Decode.from_payload ~loc payload
        | _ -> Desugaring_error.raise ~loc (Unexpected_attribute names)
      in
      Some (jkind_annot, attributes)
    | _ -> None
  ;;

  let of_type_declaration =
    Type_declaration.make_of_ast ~of_ast_internal:of_type_declaration_internal
  ;;
end

(******************************************************************************)
(** The interface to our novel syntax, which we export *)

module type AST = sig
  type t
  type ast

  val of_ast : ast -> t option
end

module Core_type = struct
  type t =
    | Jtyp_layout of Layouts.core_type
    | Jtyp_tuple of Labeled_tuples.core_type

  let of_ast_internal (feat : Feature.t) typ =
    match feat with
    | Language_extension Layouts ->
      let typ, attrs = Layouts.of_type typ in
      Some (Jtyp_layout typ, attrs)
    | Language_extension Labeled_tuples ->
      let typ, attrs = Labeled_tuples.of_typ typ in
      Some (Jtyp_tuple typ, attrs)
    | _ -> None
  ;;

  let of_ast = Core_type.make_of_ast ~of_ast_internal

  let core_type_of ~loc ~attrs t =
    let core_type =
      match t with
      | Jtyp_layout x -> Layouts.type_of ~loc x
      | Jtyp_tuple x -> Labeled_tuples.typ_of ~loc x
    in
    (* Performance hack: save an allocation if [attrs] is empty. *)
    match attrs with
    | [] -> core_type
    | _ :: _ as attrs ->
      (* See Note [Outer attributes at end] *)
      { core_type with ptyp_attributes = core_type.ptyp_attributes @ attrs }
  ;;
end

module Constructor_argument = struct
  type t = |

  let of_ast_internal (feat : Feature.t) _carg =
    match feat with
    | _ -> None
  ;;

  let of_ast = Constructor_argument.make_of_ast ~of_ast_internal
end

module Expression = struct
  type t =
    | Jexp_comprehension of Comprehensions.expression
    | Jexp_immutable_array of Immutable_arrays.expression
    | Jexp_layout of Layouts.expression
    | Jexp_n_ary_function of N_ary_functions.expression
    | Jexp_tuple of Labeled_tuples.expression

  let of_ast_internal (feat : Feature.t) expr =
    match feat with
    | Language_extension Comprehensions ->
      let expr, attrs = Comprehensions.comprehension_expr_of_expr expr in
      Some (Jexp_comprehension expr, attrs)
    | Language_extension Immutable_arrays ->
      let expr, attrs = Immutable_arrays.of_expr expr in
      Some (Jexp_immutable_array expr, attrs)
    | Language_extension Layouts ->
      let expr, attrs = Layouts.of_expr expr in
      Some (Jexp_layout expr, attrs)
    | Builtin ->
      (match N_ary_functions.of_expr expr with
       | Some (expr, attrs) -> Some (Jexp_n_ary_function expr, attrs)
       | None -> None)
    | Language_extension Labeled_tuples ->
      let expr, attrs = Labeled_tuples.of_expr expr in
      Some (Jexp_tuple expr, attrs)
    | _ -> None
  ;;

  let of_ast = Expression.make_of_ast ~of_ast_internal

  let expr_of ~loc ~attrs t =
    let expr =
      match t with
      | Jexp_comprehension x -> Comprehensions.expr_of ~loc x
      | Jexp_immutable_array x -> Immutable_arrays.expr_of ~loc x
      | Jexp_layout x -> Layouts.expr_of ~loc x
      | Jexp_n_ary_function x -> N_ary_functions.expr_of ~loc x
      | Jexp_tuple x -> Labeled_tuples.expr_of ~loc x
    in
    (* Performance hack: save an allocation if [attrs] is empty. *)
    match attrs with
    | [] -> expr
    | _ :: _ as attrs ->
      (* See Note [Outer attributes at end] *)
      { expr with pexp_attributes = expr.pexp_attributes @ attrs }
  ;;
end

module Pattern = struct
  type t =
    | Jpat_immutable_array of Immutable_arrays.pattern
    | Jpat_layout of Layouts.pattern
    | Jpat_tuple of Labeled_tuples.pattern

  let of_ast_internal (feat : Feature.t) pat =
    match feat with
    | Language_extension Immutable_arrays ->
      let expr, attrs = Immutable_arrays.of_pat pat in
      Some (Jpat_immutable_array expr, attrs)
    | Language_extension Layouts ->
      let pat, attrs = Layouts.of_pat pat in
      Some (Jpat_layout pat, attrs)
    | Language_extension Labeled_tuples ->
      let expr, attrs = Labeled_tuples.of_pat pat in
      Some (Jpat_tuple expr, attrs)
    | _ -> None
  ;;

  let of_ast = Pattern.make_of_ast ~of_ast_internal

  let pat_of ~loc ~attrs t =
    let pat =
      match t with
      | Jpat_immutable_array x -> Immutable_arrays.pat_of ~loc x
      | Jpat_layout x -> Layouts.pat_of ~loc x
      | Jpat_tuple x -> Labeled_tuples.pat_of ~loc x
    in
    (* Performance hack: save an allocation if [attrs] is empty. *)
    match attrs with
    | [] -> pat
    | _ :: _ as attrs ->
      (* See Note [Outer attributes at end] *)
      { pat with ppat_attributes = pat.ppat_attributes @ attrs }
  ;;
end

module Module_type = struct
  type t = Jmty_strengthen of Strengthen.module_type

  let of_ast_internal (feat : Feature.t) mty =
    match feat with
    | Language_extension Module_strengthening ->
      let mty, attrs = Strengthen.of_mty mty in
      Some (Jmty_strengthen mty, attrs)
    | _ -> None
  ;;

  let of_ast = Module_type.make_of_ast ~of_ast_internal

  let mty_of ~loc ~attrs t =
    let mty =
      match t with
      | Jmty_strengthen x -> Strengthen.mty_of ~loc x
    in
    (* Performance hack: save an allocation if [attrs] is empty. *)
    match attrs with
    | [] -> mty
    | _ :: _ as attrs ->
      (* See Note [Outer attributes at end] *)
      { mty with pmty_attributes = mty.pmty_attributes @ attrs }
  ;;
end

module Signature_item = struct
  type t = Jsig_include_functor of Include_functor.signature_item

  let of_ast_internal (feat : Feature.t) sigi =
    match feat with
    | Language_extension Include_functor ->
      Some (Jsig_include_functor (Include_functor.of_sig_item sigi))
    | _ -> None
  ;;

  let of_ast = Signature_item.make_of_ast ~of_ast_internal
end

module Structure_item = struct
  type t = Jstr_include_functor of Include_functor.structure_item

  let of_ast_internal (feat : Feature.t) stri =
    match feat with
    | Language_extension Include_functor ->
      Some (Jstr_include_functor (Include_functor.of_str_item stri))
    | _ -> None
  ;;

  let of_ast = Structure_item.make_of_ast ~of_ast_internal
end

module Extension_constructor = struct
  type t = Jext_layout of Layouts.extension_constructor

  let of_ast_internal (feat : Feature.t) ext =
    match feat with
    | Language_extension Layouts ->
      let ext, attrs = Layouts.of_extension_constructor ext in
      Some (Jext_layout ext, attrs)
    | _ -> None
  ;;

  let of_ast = Extension_constructor.make_of_ast ~of_ast_internal

  let extension_constructor_of ~loc ~name ~attrs ?info ?docs t =
    let ext_ctor =
      match t with
      | Jext_layout lext -> Layouts.extension_constructor_of ~loc ~name ?info ?docs lext
    in
    (* Performance hack: save an allocation if [attrs] is empty. *)
    match attrs with
    | [] -> ext_ctor
    | _ :: _ as attrs ->
      (* See Note [Outer attributes at end] *)
      { ext_ctor with pext_attributes = ext_ctor.pext_attributes @ attrs }
  ;;
end
