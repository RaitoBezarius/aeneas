(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [external]: external types.
-- This is a template file: rename it to "TypesExternal.lean" and fill the holes. *)
Require Import Primitives.
Import Primitives.
Require Import Coq.ZArith.ZArith.
Require Import List.
Import ListNotations.
Local Open Scope Primitives_scope.
Module External_TypesExternal_Template.

(** [core::cell::Cell]
    Source: '/rustc/65ea825f4021eaf77f1b25139969712d65b435a4/library/core/src/cell.rs', lines 294:0-294:26
    Name pattern: core::cell::Cell *)
Axiom core_cell_Cell_t : forall (T : Type), Type.

(** The state type used in the state-error monad *)
Axiom state : Type.

End External_TypesExternal_Template.
