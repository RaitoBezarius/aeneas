(** This module is used to extract the pure ASTs to various theorem provers.
    It defines utilities and helpers to make the work as easy as possible:
    we try to factorize as much as possible the different extractions to the
    backends we target.
 *)

open Errors
open Pure
open TranslateCore
module C = Contexts
module RegionVarId = T.RegionVarId

(** The local logger *)
let log = L.pure_to_extract_log

type region_group_info = {
  id : RegionGroupId.id;
      (** The id of the region group.
          Note that a simple way of generating unique names for backward
          functions is to use the region group ids.
       *)
  region_names : string option list;
      (** The names of the region variables included in this group.
          Note that names are not always available...
       *)
}

module StringSet = Collections.MakeSet (Collections.OrderedString)
module StringMap = Collections.MakeMap (Collections.OrderedString)

type name = Identifiers.name

type name_formatter = {
  bool_name : string;
  char_name : string;
  int_name : integer_type -> string;
  str_name : string;
  field_name : string -> string -> string;
      (** Inputs:
          - type name
          - field name
       *)
  variant_name : name -> string -> string;
      (** Inputs:
          - type name
          - variant name
       *)
  type_name : name -> string;  (** Provided a basename, compute a type name. *)
  fun_name : A.fun_id -> name -> int -> region_group_info option -> string;
      (** Inputs:
          - function id: this is especially useful to identify whether the
            function is an assumed function or a local function
          - function basename
          - number of region groups
          - region group information in case of a backward function
            (`None` if forward function)
       *)
  var_basename : StringSet.t -> ty -> string;
      (** Generates a variable basename.
      
          Inputs:
          - the set of names used in the context so far
          - the type of the variable (can be useful for heuristics, in order
            not to always use "x" for instance, whenever naming anonymous
            variables)

          Note that once the formatter generated a basename, we add an index
          if necessary to prevent name clashes: the burden of name clashes checks
          is thus on the caller's side.
       *)
  type_var_basename : StringSet.t -> string;
      (** Generates a type variable basename. *)
  append_index : string -> int -> string;
      (** Appends an index to a name - we use this to generate unique
          names: when doing so, the role of the formatter is just to concatenate
          indices to names, the responsability of finding a proper index is
          delegated to helper functions.
       *)
}
(** A name formatter's role is to come up with name suggestions.
    For instance, provided some information about a function (its basename,
    information about the region group, etc.) it should come up with an
    appropriate name for the forward/backward function.
    
    It can of course apply many transformations, like changing to camel case/
    snake case, adding prefixes/suffixes, etc.
 *)

let compute_type_def_name (fmt : name_formatter) (def : type_def) : string =
  fmt.type_name def.name

(** A helper function: generates a function suffix from a region group
    information.
    TODO: move all those helpers.
*)
let default_fun_suffix (num_region_groups : int) (rg : region_group_info option)
    : string =
  (* There are several cases:
     - [rg] is `Some`: this is a forward function:
       - if there are no region groups (i.e., no backward functions) we don't
         add any suffix
       - if there are region gruops, we add "_fwd"
     - [rg] is `None`: this is a backward function:
       - this function has one region group: we add "_back"
       - this function has several backward function: we add "_back" and an
         additional suffix to identify the precise backward function
  *)
  match rg with
  | None -> if num_region_groups = 0 then "" else "_fwd"
  | Some rg ->
      assert (num_region_groups > 0);
      if num_region_groups = 1 then (* Exactly one backward function *)
        "_back"
      else if
        (* Several region groups/backward functions:
           - if all the regions in the group have names, we use those names
           - otherwise we use an index
        *)
        List.for_all Option.is_some rg.region_names
      then
        (* Concatenate the region names *)
        "_back" ^ String.concat "" (List.map Option.get rg.region_names)
      else (* Use the region index *)
        "_back" ^ RegionGroupId.to_string rg.id

(** Extract information from a function, and give this information to a
    [name_formatter] to generate a function's name.
    
    Note that we need region information coming from CFIM (when generating
    the name for a backward function, we try to use the names of the regions
    to 
 *)
let compute_fun_def_name (ctx : trans_ctx) (fmt : name_formatter)
    (fun_id : A.fun_id) (rg_id : RegionGroupId.id option) : string =
  (* Lookup the function CFIM signature (we need the region information) *)
  let sg = CfimAstUtils.lookup_fun_sig fun_id ctx.fun_context.fun_defs in
  let basename = CfimAstUtils.lookup_fun_name fun_id ctx.fun_context.fun_defs in
  (* Compute the regions information *)
  let num_region_groups = List.length sg.regions_hierarchy in
  let rg_info =
    match rg_id with
    | None -> None
    | Some rg_id ->
        let rg = RegionGroupId.nth sg.regions_hierarchy rg_id in
        let regions =
          List.map (fun rid -> RegionVarId.nth sg.region_params rid) rg.regions
        in
        let region_names =
          List.map (fun (r : T.region_var) -> r.name) regions
        in
        Some { id = rg.id; region_names }
  in
  fmt.fun_name fun_id basename num_region_groups rg_info

(** We use identifiers to look for name clashes *)
type id =
  | FunId of A.fun_id * RegionGroupId.id option
  | TypeId of type_id
  | VariantId of TypeDefId.id * VariantId.id
      (** If often happens that variant names must be unique (it is the case in
          F* ) which is why we register them here.
       *)
  | TypeVarId of TypeVarId.id
  | VarId of VarId.id
  | UnknownId
      (** Used for stored various strings like keywords, definitions which
          should always be in context, etc. and which can't be linked to one
          of the above.
       *)
[@@deriving show, ord]

module IdOrderedType = struct
  type t = id

  let compare = compare_id

  let to_string = show_id

  let pp_t = pp_id

  let show_t = show_id
end

module IdMap = Collections.MakeMap (IdOrderedType)

type names_map = {
  id_to_name : string IdMap.t;
  name_to_id : id StringMap.t;
      (** The name to id map is used to look for name clashes, and generate nice
          debugging messages: if there is a name clash, it is useful to know
          precisely which identifiers are mapped to the same name...
       *)
  names_set : StringSet.t;
}
(** The names map stores the mappings from names to identifiers and vice-versa.

      We use it for lookups (during the translation) and to check for name clashes.
  *)

let names_map_add (id : id) (name : string) (nm : names_map) : names_map =
  (* Sanity check: no clashes *)
  assert (not (StringSet.mem name nm.names_set));
  (* Insert *)
  let id_to_name = IdMap.add id name nm.id_to_name in
  let name_to_id = StringMap.add name id nm.name_to_id in
  let names_set = StringSet.add name nm.names_set in
  { id_to_name; name_to_id; names_set }

(* TODO: remove those functions? We use the ones of extraction_ctx *)
let names_map_find (id : id) (nm : names_map) : string =
  IdMap.find id nm.id_to_name

let names_map_find_function (id : A.fun_id) (rg : RegionGroupId.id option)
    (nm : names_map) : string =
  names_map_find (FunId (id, rg)) nm

let names_map_find_local_function (id : FunDefId.id)
    (rg : RegionGroupId.id option) (nm : names_map) : string =
  names_map_find_function (A.Local id) rg nm

let names_map_find_type (id : type_id) (nm : names_map) : string =
  assert (id <> Tuple);
  names_map_find (TypeId id) nm

let names_map_find_local_type (id : TypeDefId.id) (nm : names_map) : string =
  names_map_find_type (AdtId id) nm

let names_map_find_var (id : VarId.id) (nm : names_map) : string =
  names_map_find (VarId id) nm

let names_map_find_type_var (id : TypeVarId.id) (nm : names_map) : string =
  names_map_find (TypeVarId id) nm

(** Make a (variable) basename unique (by adding an index).

    We do this in an inefficient manner (by testing all indices starting from
    0) but it shouldn't be a bottleneck.
    
    [append]: appends an index to a string
 *)
let basename_to_unique (names_set : StringSet.t)
    (append : string -> int -> string) (basename : string) : string =
  let rec gen (i : int) : string =
    let s = append basename i in
    if StringSet.mem s names_set then gen (i + 1) else s
  in
  if StringSet.mem basename names_set then gen 0 else basename

type extraction_ctx = {
  trans_ctx : trans_ctx;
  names_map : names_map;
  fmt : name_formatter;
  indent_incr : int;
      (** The indent increment we insert whenever we need to indent more *)
}
(** Extraction context.

    Note that the extraction context contains information coming from the
    CFIM AST (not only the pure AST). This is useful for naming, for instance:
    we use the region information to generate the names of the backward
    functions, etc.
 *)

let ctx_add (id : id) (name : string) (ctx : extraction_ctx) : extraction_ctx =
  (* TODO : nice debugging message if collision *)
  let names_map = names_map_add id name ctx.names_map in
  { ctx with names_map }

let ctx_find (id : id) (ctx : extraction_ctx) : string =
  IdMap.find id ctx.names_map.id_to_name

let ctx_find_function (id : A.fun_id) (rg : RegionGroupId.id option)
    (ctx : extraction_ctx) : string =
  ctx_find (FunId (id, rg)) ctx

let ctx_find_local_function (id : FunDefId.id) (rg : RegionGroupId.id option)
    (ctx : extraction_ctx) : string =
  ctx_find_function (A.Local id) rg ctx

let ctx_find_type (id : type_id) (ctx : extraction_ctx) : string =
  assert (id <> Tuple);
  ctx_find (TypeId id) ctx

let ctx_find_local_type (id : TypeDefId.id) (ctx : extraction_ctx) : string =
  ctx_find_type (AdtId id) ctx

let ctx_find_var (id : VarId.id) (ctx : extraction_ctx) : string =
  ctx_find (VarId id) ctx

let ctx_find_type_var (id : TypeVarId.id) (ctx : extraction_ctx) : string =
  ctx_find (TypeVarId id) ctx

(** Generate a unique type variable name and add to the context *)
let ctx_add_type_var (basename : string) (id : TypeVarId.id)
    (ctx : extraction_ctx) : extraction_ctx * string =
  let name =
    basename_to_unique ctx.names_map.names_set ctx.fmt.append_index basename
  in
  let ctx = ctx_add (TypeVarId id) name ctx in
  (ctx, name)

(** See [ctx_add_type_var] *)
let ctx_add_type_vars (vars : (string * TypeVarId.id) list)
    (ctx : extraction_ctx) : extraction_ctx * string list =
  List.fold_left_map
    (fun ctx (name, id) -> ctx_add_type_var name id ctx)
    ctx vars

let ctx_add_type_params (vars : type_var list) (ctx : extraction_ctx) :
    extraction_ctx * string list =
  List.fold_left_map
    (fun ctx (var : type_var) -> ctx_add_type_var var.name var.index ctx)
    ctx vars

let ctx_add_type_def (def : type_def) (ctx : extraction_ctx) :
    extraction_ctx * string =
  let def_name = ctx.fmt.type_name def.name in
  let ctx = ctx_add (TypeId (AdtId def.def_id)) def_name ctx in
  (ctx, def_name)

let ctx_add_variant (def : type_def) (variant_id : VariantId.id)
    (variant : variant) (ctx : extraction_ctx) : extraction_ctx * string =
  let name = ctx.fmt.variant_name def.name variant.variant_name in
  let ctx = ctx_add (VariantId (def.def_id, variant_id)) name ctx in
  (ctx, name)

let ctx_add_variants (def : type_def) (variants : (VariantId.id * variant) list)
    (ctx : extraction_ctx) : extraction_ctx * string list =
  List.fold_left_map
    (fun ctx (vid, v) -> ctx_add_variant def vid v ctx)
    ctx variants