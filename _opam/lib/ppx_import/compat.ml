type module_type_407 =
  | Mty_ident of Path.t
  | Mty_signature of Types.signature
  | Mty_functor of Ident.t * Types.module_type option * Types.module_type
  | Mty_alias of unit * Path.t

let migrate_module_type : Types.module_type -> module_type_407 = function
  | Mty_ident p -> Mty_ident p
  | Mty_signature s -> Mty_signature s
  | Mty_functor (fp, mt) -> (
    match fp with
    | Unit -> Mty_functor (Ident.create_local "_", None, mt)
    | Named (i, mt) ->
      let i = match i with None -> Ident.create_local "_" | Some i -> i in
      Mty_functor (i, Some mt, mt) )
  | Mty_alias p -> Mty_alias ((), p)

type signature_item_407 =
  | Sig_value of Ident.t * Types.value_description
  | Sig_type of Ident.t * Types.type_declaration * Types.rec_status
  | Sig_typext of Ident.t * Types.extension_constructor * Types.ext_status
  | Sig_module of Ident.t * Types.module_declaration * Types.rec_status
  | Sig_modtype of Ident.t * Types.modtype_declaration
  | Sig_class of Ident.t * Types.class_declaration * Types.rec_status
  | Sig_class_type of Ident.t * Types.class_type_declaration * Types.rec_status

let migrate_signature_item : Types.signature_item -> signature_item_407 =
  function
  | Sig_value (id, vd, _) -> Sig_value (id, vd)
  | Sig_type (id, td, r, _) -> Sig_type (id, td, r)
  | Sig_typext (id, ec, es, _) -> Sig_typext (id, ec, es)
  | Sig_module (id, _, md, rs, _) -> Sig_module (id, md, rs)
  | Sig_modtype (id, td, _) -> Sig_modtype (id, td)
  | Sig_class (id, cd, rs, _) -> Sig_class (id, cd, rs)
  | Sig_class_type (id, ctd, rs, _) -> Sig_class_type (id, ctd, rs)

type ('lbl, 'cstr) type_kind_412 =
  | Type_abstract
  | Type_record of 'lbl list * Types.record_representation
  | Type_variant of 'cstr list
  | Type_open

let migrate_type_kind :
    ('lbl, 'cstr) Types.type_kind -> ('lbl, 'cstr) type_kind_412 = function
  | Type_abstract _ -> Type_abstract
  | Type_record (lbl, repr) -> Type_record (lbl, repr)
  | Type_variant (cstr, _) -> Type_variant cstr
  | Type_open -> Type_open

let init_path () = Compmisc.init_path ()

let lookup_module ~loc lid env = Env.lookup_module ~loc lid env |> fst
let find_type env ~loc head_id = Env.lookup_type ~loc head_id env
let find_modtype env ~loc:_ head_id = Env.find_modtype_by_name head_id env

let get_desc = Types.get_desc
let row_fields = Types.row_fields
let row_field_repr = Types.row_field_repr

