(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [external]: external function declarations *)
module External.FunsExternal
open Primitives
include External.Types

#set-options "--z3rlimit 50 --fuel 1 --ifuel 1"

(** [core::mem::swap]:
    Source: '/rustc/d59363ad0b6391b7fc5bbb02c9ccf9300eef3753/library/core/src/mem/mod.rs', lines 726:0-726:42
    Name pattern: core::mem::swap *)
val core_mem_swap (t : Type0) : t -> t -> state -> result (state & (t & t))

(** [core::num::nonzero::{core::num::nonzero::NonZeroU32#14}::new]:
    Source: '/rustc/d59363ad0b6391b7fc5bbb02c9ccf9300eef3753/library/core/src/num/nonzero.rs', lines 79:16-79:57
    Name pattern: core::num::nonzero::{core::num::nonzero::NonZeroU32}::new *)
val core_num_nonzero_NonZeroU32_new
  : u32 -> state -> result (state & (option core_num_nonzero_NonZeroU32_t))

