(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [loops]: templates for the decreases clauses *)
module Loops.Clauses.Template
open Primitives
open Loops.Types

#set-options "--z3rlimit 50 --fuel 1 --ifuel 1"

(** [loops::sum]: decreases clause *)
unfold let sum_loop_decreases (max : u32) (i : u32) (s : u32) : nat = admit ()

(** [loops::sum_with_mut_borrows]: decreases clause *)
unfold
let sum_with_mut_borrows_loop_decreases (max : u32) (mi : u32) (ms : u32) : nat
  =
  admit ()

(** [loops::sum_with_shared_borrows]: decreases clause *)
unfold
let sum_with_shared_borrows_loop_decreases (max : u32) (i : u32) (s : u32) :
  nat =
  admit ()

(** [loops::clear]: decreases clause *)
unfold let clear_loop_decreases (v : vec u32) (i : usize) : nat = admit ()

(** [loops::list_mem]: decreases clause *)
unfold let list_mem_loop_decreases (x : u32) (ls : list_t u32) : nat = admit ()

(** [loops::list_nth_mut_loop]: decreases clause *)
unfold
let list_nth_mut_loop_loop_decreases (t : Type0) (ls : list_t t) (i : u32) :
  nat =
  admit ()

(** [loops::list_nth_shared_loop]: decreases clause *)
unfold
let list_nth_shared_loop_loop_decreases (t : Type0) (ls : list_t t) (i : u32) :
  nat =
  admit ()

(** [loops::get_elem_mut]: decreases clause *)
unfold
let get_elem_mut_loop_decreases (x : usize) (ls : list_t usize) : nat =
  admit ()

(** [loops::get_elem_shared]: decreases clause *)
unfold
let get_elem_shared_loop_decreases (slots : vec (list_t usize)) (x : usize)
  (ls : list_t usize) (ls0 : list_t usize) : nat =
  admit ()

(** [loops::list_nth_mut_loop_with_id]: decreases clause *)
unfold
let list_nth_mut_loop_with_id_loop_decreases (t : Type0) (i : u32)
  (ls : list_t t) : nat =
  admit ()

(** [loops::list_nth_shared_loop_with_id]: decreases clause *)
unfold
let list_nth_shared_loop_with_id_loop_decreases (t : Type0) (ls : list_t t)
  (i : u32) (ls0 : list_t t) : nat =
  admit ()

(** [loops::list_nth_mut_loop_pair]: decreases clause *)
unfold
let list_nth_mut_loop_pair_loop_decreases (t : Type0) (ls0 : list_t t)
  (ls1 : list_t t) (i : u32) : nat =
  admit ()

(** [loops::list_nth_shared_loop_pair]: decreases clause *)
unfold
let list_nth_shared_loop_pair_loop_decreases (t : Type0) (ls0 : list_t t)
  (ls1 : list_t t) (i : u32) : nat =
  admit ()

(** [loops::list_nth_mut_loop_pair_merge]: decreases clause *)
unfold
let list_nth_mut_loop_pair_merge_loop_decreases (t : Type0) (ls0 : list_t t)
  (ls1 : list_t t) (i : u32) : nat =
  admit ()

(** [loops::list_nth_shared_loop_pair_merge]: decreases clause *)
unfold
let list_nth_shared_loop_pair_merge_loop_decreases (t : Type0) (ls0 : list_t t)
  (ls1 : list_t t) (i : u32) : nat =
  admit ()

(** [loops::list_nth_mut_shared_loop_pair]: decreases clause *)
unfold
let list_nth_mut_shared_loop_pair_loop_decreases (t : Type0) (ls0 : list_t t)
  (ls1 : list_t t) (i : u32) : nat =
  admit ()

(** [loops::list_nth_mut_shared_loop_pair_merge]: decreases clause *)
unfold
let list_nth_mut_shared_loop_pair_merge_loop_decreases (t : Type0)
  (ls0 : list_t t) (ls1 : list_t t) (i : u32) : nat =
  admit ()

(** [loops::list_nth_shared_mut_loop_pair]: decreases clause *)
unfold
let list_nth_shared_mut_loop_pair_loop_decreases (t : Type0) (ls0 : list_t t)
  (ls1 : list_t t) (i : u32) : nat =
  admit ()

(** [loops::list_nth_shared_mut_loop_pair_merge]: decreases clause *)
unfold
let list_nth_shared_mut_loop_pair_merge_loop_decreases (t : Type0)
  (ls0 : list_t t) (ls1 : list_t t) (i : u32) : nat =
  admit ()

