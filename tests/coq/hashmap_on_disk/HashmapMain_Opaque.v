(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [hashmap_main]: external function declarations *)
Require Import Primitives.
Import Primitives.
Require Import Coq.ZArith.ZArith.
Local Open Scope Primitives_scope.
Require Export HashmapMain_Types.
Import HashmapMain_Types.
Module HashmapMain_Opaque.

(** [hashmap_main::hashmap_utils::deserialize]: forward function *)
Axiom hashmap_utils_deserialize_fwd
  : state -> result (state * (Hashmap_hash_map_t u64))
.

(** [hashmap_main::hashmap_utils::serialize]: forward function *)
Axiom hashmap_utils_serialize_fwd
  : Hashmap_hash_map_t u64 -> state -> result (state * unit)
.

End HashmapMain_Opaque .
