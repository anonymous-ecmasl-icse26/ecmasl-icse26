(* {{{ COPYING *(

   This file is part of Merlin, an helper for ocaml editors

   Copyright (C) 2013 - 2015 Frédéric Bour <frederic.bour(_)lakaban.net> Thomas
   Refis <refis.thomas(_)gmail.com> Simon Castellan <simon.castellan(_)iuwt.fr>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   The Software is provided "as is", without warranty of any kind, express or
   implied, including but not limited to the warranties of merchantability,
   fitness for a particular purpose and noninfringement. In no event shall the
   authors or copyright holders be liable for any claim, damages or other
   liability, whether in an action of contract, tort or otherwise, arising from,
   out of or in connection with the software or the use or other dealings in the
   Software.

   )* }}} *)
open Import

let browse_of_cmt (cmt_infos : Cmt_format.cmt_infos) : Browse_raw.node option =
  match cmt_infos.cmt_annots with
  | Implementation str -> Some (Structure str)
  | Interface sig_ -> Some (Signature sig_)
  (* TODO support these *)
  | Packed _ | Partial_implementation _ | Partial_interface _ -> None
;;

let is_directory dir =
  try Sys.is_directory dir with
  | Sys_error _ -> false
;;

type error = Build_dir_not_found of string

let find_build_dir ({ name; uri } : WorkspaceFolder.t) =
  let build_dir = Filename.concat (Uri.to_path uri) "_build/default" in
  if is_directory build_dir then Ok build_dir else Error (Build_dir_not_found name)
;;

type cm_file =
  | Cmt of string
  | Cmti of string

let string_of_cm cm =
  match cm with
  | Cmt f | Cmti f -> f
;;

module Outline : sig
  (* Like merlin's original outline but doesn't print any types. The types
     useless anyway and make it impossible to run this concurrently to other
     operations that involve the typer. *)
  val get : Merlin_analysis.Browse_tree.t list -> Query_protocol.item list
end = struct
  module Location = Loc
  open Merlin_utils
  open Merlin_analysis
  open Std
  open Option.Infix
  open Typedtree
  open Browse_raw
  open Browse_tree

  let name_of_patt = function
    | { pat_desc = Tpat_var (_, name, _); _ } -> Some name
    | _ -> None
  ;;

  let mk ?(children = []) ~location ~deprecated outline_kind (id : string Location.loc) =
    { Query_protocol.outline_kind
    ; outline_type = None
    ; location
    ; selection = id.loc
    ; children
    ; outline_name = id.txt
    ; deprecated
    }
  ;;

  let get_class_field_desc_infos = function
    | Typedtree.Tcf_val (str_loc, _, _, _, _) -> Some (str_loc, `Value)
    | Typedtree.Tcf_method (str_loc, _, _) -> Some (str_loc, `Method)
    | _ -> None
  ;;

  let rec summarize node =
    let location = node.t_loc in
    match node.t_node with
    | Value_binding vb ->
      let deprecated = Type_utils.is_deprecated vb.vb_attributes in
      (match name_of_patt vb.vb_pat with
       | None -> None
       | Some name -> Some (mk ~location ~deprecated `Value name))
    | Value_description vd ->
      let deprecated = Type_utils.is_deprecated vd.val_attributes in
      Some (mk ~location ~deprecated `Value vd.val_name)
    | Module_declaration md ->
      let children = get_mod_children node in
      (match md.md_name with
       | { txt = None; _ } -> None
       | { txt = Some txt; loc } ->
         let deprecated = Type_utils.is_deprecated md.md_attributes in
         Some (mk ~children ~location ~deprecated `Module { txt; loc }))
    | Module_binding mb ->
      let children = get_mod_children node in
      (match mb.mb_name with
       | { txt = None; _ } -> None
       | { txt = Some txt; loc } ->
         let deprecated = Type_utils.is_deprecated mb.mb_attributes in
         Some (mk ~children ~location ~deprecated `Module { txt; loc }))
    | Module_type_declaration mtd ->
      let children = get_mod_children node in
      let deprecated = Type_utils.is_deprecated mtd.mtd_attributes in
      Some (mk ~deprecated ~children ~location `Modtype mtd.mtd_name)
    | Type_declaration td ->
      let children =
        List.concat_map (Lazy.force node.t_children) ~f:(fun child ->
          match child.t_node with
          | Type_kind _ ->
            List.map (Lazy.force child.t_children) ~f:(fun x ->
              match x.t_node with
              | Constructor_declaration c ->
                let deprecated = Type_utils.is_deprecated c.cd_attributes in
                mk `Constructor c.cd_name ~deprecated ~location:c.cd_loc
              | Label_declaration ld ->
                let deprecated = Type_utils.is_deprecated ld.ld_attributes in
                mk `Label ld.ld_name ~deprecated ~location:ld.ld_loc
              | _ -> assert false
              (* ! *))
          | _ -> [])
      in
      let deprecated = Type_utils.is_deprecated td.typ_attributes in
      Some (mk ~children ~location ~deprecated `Type td.typ_name)
    | Type_extension te ->
      let name = Path.name te.tyext_path in
      let children =
        List.filter_map (Lazy.force node.t_children) ~f:(fun x ->
          summarize x >>| fun x -> { x with Query_protocol.outline_kind = `Constructor })
      in
      let deprecated = Type_utils.is_deprecated te.tyext_attributes in
      Some
        { Query_protocol.outline_name = name
        ; outline_kind = `Type
        ; outline_type = None
        ; location
        ; selection = te.tyext_txt.loc
        ; children
        ; deprecated
        }
    | Extension_constructor ec ->
      let deprecated = Type_utils.is_deprecated ec.ext_attributes in
      Some (mk ~location `Exn ec.ext_name ~deprecated)
    | Class_declaration cd ->
      let children = List.concat_map (Lazy.force node.t_children) ~f:get_class_elements in
      let deprecated = Type_utils.is_deprecated cd.ci_attributes in
      Some (mk ~children ~location `Class cd.ci_id_name ~deprecated)
    | _ -> None

  and get_class_elements node =
    match node.t_node with
    | Class_expr _ -> List.concat_map (Lazy.force node.t_children) ~f:get_class_elements
    | Class_structure _ ->
      List.filter_map (Lazy.force node.t_children) ~f:(fun child ->
        match child.t_node with
        | Class_field cf ->
          (match get_class_field_desc_infos cf.cf_desc with
           | Some (str_loc, outline_kind) ->
             let deprecated = Type_utils.is_deprecated cf.cf_attributes in
             Some
               { Query_protocol.outline_name = str_loc.Location.txt
               ; outline_kind
               ; outline_type = None
               ; location = cf.cf_loc
               ; selection = str_loc.Location.loc
               ; children = []
               ; deprecated
               }
           | None -> None)
        | _ -> None)
    | _ -> []

  and get_mod_children node =
    List.concat_map (Lazy.force node.t_children) ~f:remove_mod_indir

  and remove_mod_indir node =
    match node.t_node with
    | Module_expr _ | Module_type _ ->
      List.concat_map (Lazy.force node.t_children) ~f:remove_mod_indir
    | _ -> remove_top_indir node

  and remove_top_indir t =
    match t.t_node with
    | Structure _ | Signature _ ->
      List.concat_map ~f:remove_top_indir (Lazy.force t.t_children)
    | Signature_item _ | Structure_item _ ->
      List.filter_map (Lazy.force t.t_children) ~f:summarize
    | _ -> []
  ;;

  let get browses = List.concat @@ List.rev_map ~f:remove_top_indir browses
end

exception Cancelled

let outline_kind kind : SymbolKind.t =
  match kind with
  | `Value -> Function
  | `Constructor -> Constructor
  | `Label -> Property
  | `Module -> Module
  | `Modtype -> Module
  | `Type -> String
  | `Exn -> Constructor
  | `Class -> Class
  | `ClassType -> Interface
  | `Method -> Method
;;

let rec symbol_info ?containerName uri (item : Query_protocol.item) =
  let info =
    let kind = outline_kind item.outline_kind in
    let location = { Location.uri; range = Range.of_loc item.location } in
    SymbolInformation.create
      ~name:item.outline_name
      ~kind
      ~deprecated:false
      ~location
      ?containerName
      ()
  in
  let children =
    List.concat_map item.children ~f:(symbol_info uri ~containerName:info.name)
  in
  info :: children
;;

let symbols_of_outline uri outline = List.concat_map ~f:(symbol_info uri) outline

let symbols_from_cm_file ~filter root_uri (cancel : Fiber.Cancel.t option) cm_file =
  let cmt =
    let filename = string_of_cm cm_file in
    let cancelled =
      match cancel with
      | None -> false
      | Some cancel -> Fiber.Cancel.fired cancel
    in
    if cancelled then raise Cancelled else Cmt_format.read_cmt filename
  in
  match cmt.cmt_sourcefile with
  | None -> []
  | Some sourcefile ->
    (match Filename.extension sourcefile with
     | ".ml" | ".mli" ->
       (match browse_of_cmt cmt with
        | None -> []
        | Some browse ->
          let outline =
            let browse_tree = Merlin_analysis.Browse_tree.of_node browse in
            Outline.get [ browse_tree ]
          in
          let loc = Mbrowse.node_loc browse in
          let fname = loc.loc_start.pos_fname in
          let uri = Uri.of_path (Filename.concat root_uri fname) in
          filter (symbols_of_outline uri outline))
     | _ -> [])
;;

let find_cm_files dir =
  let choose_file f1 f2 =
    match f1, f2 with
    | (Cmt _ as f), _ | _, (Cmt _ as f) -> f
    | (Cmti _ as f), Cmti _ -> f
  in
  (* TODO we could get into a symlink loop here so we should we be careful *)
  let rec loop acc dir =
    let contents = Sys.readdir dir in
    Array.fold contents ~init:acc ~f:(fun acc fname ->
      let path = Filename.concat dir fname in
      if is_directory path
      then loop acc path
      else (
        match String.rsplit2 ~on:'.' path with
        | Some (path_without_ext, "cmt") -> String.Map.set acc path_without_ext (Cmt path)
        | Some (path_without_ext, "cmti") ->
          let current_file = String.Map.find acc path_without_ext in
          let cmi_file = Cmti path in
          (match current_file with
           | None -> String.Map.set acc path_without_ext cmi_file
           | Some current_file ->
             String.Map.set acc path_without_ext (choose_file current_file cmi_file))
        | _ -> acc))
  in
  loop String.Map.empty dir |> String.Map.values
;;

let run
      ({ query; _ } : WorkspaceSymbolParams.t)
      (workspace_folders : WorkspaceFolder.t list)
      (cancel : Fiber.Cancel.t option)
  =
  let filter =
    match query with
    | "" -> fun x -> x
    | query ->
      let re = Re.str query |> Re.compile in
      List.filter ~f:(fun (symbol : SymbolInformation.t) -> Re.execp re symbol.name)
  in
  try
    Ok
      (List.map workspace_folders ~f:(fun (workspace_folder : WorkspaceFolder.t) ->
         let open Result.O in
         let+ build_dir = find_build_dir workspace_folder in
         let cm_files = find_cm_files build_dir in
         let path =
           let uri = workspace_folder.uri in
           Uri.to_path uri
         in
         List.concat_map ~f:(symbols_from_cm_file ~filter path cancel) cm_files))
  with
  | Cancelled -> Error `Cancelled
;;

let run server (state : State.t) (params : WorkspaceSymbolParams.t) =
  let open Fiber.O in
  let* symbols, errors =
    let workspaces = Workspaces.workspace_folders (State.workspaces state) in
    let* thread = Lazy_fiber.force state.symbols_thread in
    let+ symbols_results =
      let* cancel = Server.cancel_token () in
      let task =
        Lev_fiber.Thread.task thread ~f:(fun () -> run params workspaces cancel)
      in
      let* res, cancel =
        match task with
        | Error `Stopped -> Fiber.never
        | Ok task ->
          let maybe_cancel =
            match cancel with
            | None ->
              fun f ->
                let+ res = f () in
                res, Fiber.Cancel.Not_cancelled
            | Some token ->
              let on_cancel () = Lev_fiber.Thread.cancel task in
              fun f -> Fiber.Cancel.with_handler token ~on_cancel f
          in
          maybe_cancel @@ fun () -> Lev_fiber.Thread.await task
      in
      match cancel with
      | Cancelled () ->
        let e =
          Jsonrpc.Response.Error.make ~code:RequestCancelled ~message:"cancelled" ()
        in
        raise (Jsonrpc.Response.Error.E e)
      | Fiber.Cancel.Not_cancelled ->
        (match res with
         | Ok (Ok s) -> Fiber.return s
         | Ok (Error `Cancelled) -> assert false
         | Error `Cancelled -> assert false
         | Error (`Exn exn) -> Exn_with_backtrace.reraise exn)
    in
    List.partition_map symbols_results ~f:(function
      | Ok r -> Left r
      | Error e -> Right e)
  in
  let+ () =
    match errors with
    | [] -> Fiber.return ()
    | _ :: _ ->
      let msg =
        let message =
          List.map errors ~f:(function Build_dir_not_found workspace_name ->
              workspace_name)
          |> String.concat ~sep:", "
          |> sprintf "No build directory found in workspace(s): %s"
        in
        ShowMessageParams.create ~message ~type_:Warning
      in
      task_if_running state.detached ~f:(fun () ->
        Server.notification server (ShowMessage msg))
  in
  Some (List.concat symbols)
;;
