(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [constants] *)
Require Import Primitives.
Import Primitives.
Require Import Coq.ZArith.ZArith.
Local Open Scope Primitives_scope.
Module Constants.

(** [constants::X0] *)
Definition x0_body : result u32 := Return 0%u32.
Definition x0_c : u32 := x0_body%global.

(** [core::num::u32::{9}::MAX] *)
Definition core_num_u32_max_body : result u32 := Return 4294967295%u32.
Definition core_num_u32_max_c : u32 := core_num_u32_max_body%global.

(** [constants::X1] *)
Definition x1_body : result u32 := Return core_num_u32_max_c.
Definition x1_c : u32 := x1_body%global.

(** [constants::X2] *)
Definition x2_body : result u32 := Return 3%u32.
Definition x2_c : u32 := x2_body%global.

(** [constants::incr]: forward function *)
Definition incr_fwd (n : u32) : result u32 :=
  u32_add n 1%u32.

(** [constants::X3] *)
Definition x3_body : result u32 := incr_fwd 32%u32.
Definition x3_c : u32 := x3_body%global.

(** [constants::mk_pair0]: forward function *)
Definition mk_pair0_fwd (x : u32) (y : u32) : result (u32 * u32) :=
  Return (x, y)
.

(** [constants::Pair] *)
Record Pair_t (T1 T2 : Type) := mkPair_t { Pair_x : T1; Pair_y : T2; }.

Arguments mkPair_t {T1} {T2} _ _.
Arguments Pair_x {T1} {T2}.
Arguments Pair_y {T1} {T2}.

(** [constants::mk_pair1]: forward function *)
Definition mk_pair1_fwd (x : u32) (y : u32) : result (Pair_t u32 u32) :=
  Return {| Pair_x := x; Pair_y := y |}
.

(** [constants::P0] *)
Definition p0_body : result (u32 * u32) := mk_pair0_fwd 0%u32 1%u32.
Definition p0_c : (u32 * u32) := p0_body%global.

(** [constants::P1] *)
Definition p1_body : result (Pair_t u32 u32) := mk_pair1_fwd 0%u32 1%u32.
Definition p1_c : Pair_t u32 u32 := p1_body%global.

(** [constants::P2] *)
Definition p2_body : result (u32 * u32) := Return (0%u32, 1%u32).
Definition p2_c : (u32 * u32) := p2_body%global.

(** [constants::P3] *)
Definition p3_body : result (Pair_t u32 u32) :=
  Return {| Pair_x := 0%u32; Pair_y := 1%u32 |}
.
Definition p3_c : Pair_t u32 u32 := p3_body%global.

(** [constants::Wrap] *)
Record Wrap_t (T : Type) := mkWrap_t { Wrap_val : T; }.

Arguments mkWrap_t {T} _.
Arguments Wrap_val {T}.

(** [constants::Wrap::{0}::new]: forward function *)
Definition wrap_new_fwd (T : Type) (val : T) : result (Wrap_t T) :=
  Return {| Wrap_val := val |}
.

(** [constants::Y] *)
Definition y_body : result (Wrap_t i32) := wrap_new_fwd i32 2%i32.
Definition y_c : Wrap_t i32 := y_body%global.

(** [constants::unwrap_y]: forward function *)
Definition unwrap_y_fwd : result i32 :=
  Return y_c.(Wrap_val).

(** [constants::YVAL] *)
Definition yval_body : result i32 := unwrap_y_fwd.
Definition yval_c : i32 := yval_body%global.

(** [constants::get_z1::Z1] *)
Definition get_z1_z1_body : result i32 := Return 3%i32.
Definition get_z1_z1_c : i32 := get_z1_z1_body%global.

(** [constants::get_z1]: forward function *)
Definition get_z1_fwd : result i32 :=
  Return get_z1_z1_c.

(** [constants::add]: forward function *)
Definition add_fwd (a : i32) (b : i32) : result i32 :=
  i32_add a b.

(** [constants::Q1] *)
Definition q1_body : result i32 := Return 5%i32.
Definition q1_c : i32 := q1_body%global.

(** [constants::Q2] *)
Definition q2_body : result i32 := Return q1_c.
Definition q2_c : i32 := q2_body%global.

(** [constants::Q3] *)
Definition q3_body : result i32 := add_fwd q2_c 3%i32.
Definition q3_c : i32 := q3_body%global.

(** [constants::get_z2]: forward function *)
Definition get_z2_fwd : result i32 :=
  i <- get_z1_fwd; i0 <- add_fwd i q3_c; add_fwd q1_c i0
.

(** [constants::S1] *)
Definition s1_body : result u32 := Return 6%u32.
Definition s1_c : u32 := s1_body%global.

(** [constants::S2] *)
Definition s2_body : result u32 := incr_fwd s1_c.
Definition s2_c : u32 := s2_body%global.

(** [constants::S3] *)
Definition s3_body : result (Pair_t u32 u32) := Return p3_c.
Definition s3_c : Pair_t u32 u32 := s3_body%global.

(** [constants::S4] *)
Definition s4_body : result (Pair_t u32 u32) := mk_pair1_fwd 7%u32 8%u32.
Definition s4_c : Pair_t u32 u32 := s4_body%global.

End Constants .
