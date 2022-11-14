(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [betree_main]: opaque function definitions *)
Require Import Primitives.
Import Primitives.
Require Import Coq.ZArith.ZArith.
Local Open Scope Primitives_scope.
Require Export BetreeMain__Types .
Import BetreeMain__Types .
Module BetreeMain__Opaque .

(** [betree_main::betree_utils::load_internal_node] *)
Axiom betree_utils_load_internal_node_fwd
  : u64 -> state -> result (state * (Betree_list_t (u64 * Betree_message_t)))
  .

(** [betree_main::betree_utils::store_internal_node] *)
Axiom betree_utils_store_internal_node_fwd
  :
  u64 -> Betree_list_t (u64 * Betree_message_t) -> state -> result (state *
    unit)
  .

(** [betree_main::betree_utils::load_leaf_node] *)
Axiom betree_utils_load_leaf_node_fwd
  : u64 -> state -> result (state * (Betree_list_t (u64 * u64)))
  .

(** [betree_main::betree_utils::store_leaf_node] *)
Axiom betree_utils_store_leaf_node_fwd
  : u64 -> Betree_list_t (u64 * u64) -> state -> result (state * unit)
  .

(** [core::option::Option::{0}::unwrap] *)
Axiom core_option_option_unwrap_fwd :
  forall(T : Type) , option T -> state -> result (state * T)
  .

End BetreeMain__Opaque .
