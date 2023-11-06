(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [array]: external function declarations *)
module Array.Opaque
open Primitives
include Array.Types

#set-options "--z3rlimit 50 --fuel 1 --ifuel 1"

(** [core::array::[T; N]::{15}::index]: forward function *)
val core_array_[T; N]_index_fwd
  (t i : Type0) (n : usize) (inst : core_ops_index_Index (slice t) i) :
  array t n -> i -> result inst.core_ops_index_Index_Output

(** [core::array::[T; N]::{16}::index_mut]: forward function *)
val core_array_[T; N]_index_mut_fwd
  (t i : Type0) (n : usize) (inst : core_ops_index_IndexMut (slice t) i) :
  array t n -> i -> result inst.index_inst.core_ops_index_Index_Output

(** [core::array::[T; N]::{16}::index_mut]: backward function 0 *)
val core_array_[T; N]_index_mut_back
  (t i : Type0) (n : usize) (inst : core_ops_index_IndexMut (slice t) i) :
  array t n -> i -> inst.index_inst.core_ops_index_Index_Output -> result
    (array t n)
