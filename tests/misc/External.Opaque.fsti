(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [external]: opaque function definitions *)
module External.Opaque
open Primitives
include External.Types

#set-options "--z3rlimit 50 --fuel 0 --ifuel 1"

(** [core::mem::swap] *)
val core_mem_swap_fwd (t : Type0) : t -> t -> state -> result (state & unit)

(** [core::mem::swap] *)
val core_mem_swap_back0 (t : Type0) : t -> t -> state -> result (state & t)

(** [core::mem::swap] *)
val core_mem_swap_back1 (t : Type0) : t -> t -> state -> result (state & t)

(** [core::num::nonzero::NonZeroU32::{14}::new] *)
val core_num_nonzero_non_zero_u32_14_new_fwd
  : u32 -> state -> result (state & (option core_num_nonzero_non_zero_u32_t))

(** [core::option::Option::{0}::unwrap] *)
val core_option_option_unwrap_fwd
  (t : Type0) : option t -> state -> result (state & t)
