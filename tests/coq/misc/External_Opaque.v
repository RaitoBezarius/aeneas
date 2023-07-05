(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [external]: external function declarations *)
Require Import Primitives.
Import Primitives.
Require Import Coq.ZArith.ZArith.
Local Open Scope Primitives_scope.
Require Export External_Types.
Import External_Types.
Module External_Opaque.

(** [core::mem::swap] *)
Axiom core_mem_swap_fwd :
  forall(T : Type), T -> T -> state -> result (state * unit)
.

(** [core::mem::swap] *)
Axiom core_mem_swap_back0 :
  forall(T : Type), T -> T -> state -> state -> result (state * T)
.

(** [core::mem::swap] *)
Axiom core_mem_swap_back1 :
  forall(T : Type), T -> T -> state -> state -> result (state * T)
.

(** [core::num::nonzero::NonZeroU32::{14}::new] *)
Axiom core_num_nonzero_non_zero_u32_new_fwd
  : u32 -> state -> result (state * (option Core_num_nonzero_non_zero_u32_t))
.

(** [core::option::Option::{0}::unwrap] *)
Axiom core_option_option_unwrap_fwd :
  forall(T : Type), option T -> state -> result (state * T)
.

End External_Opaque .
