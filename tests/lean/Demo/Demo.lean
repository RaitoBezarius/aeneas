-- THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS
-- [demo]
import Base
open Primitives

namespace demo

/- [demo::choose]:
   Source: 'src/demo.rs', lines 5:0-5:70 -/
def choose
  (T : Type) (b : Bool) (x : T) (y : T) :
  Result (T × (T → Result (T × T)))
  :=
  if b
  then let back_'a := fun ret => Result.ret (ret, y)
       Result.ret (x, back_'a)
  else let back_'a := fun ret => Result.ret (x, ret)
       Result.ret (y, back_'a)

/- [demo::mul2_add1]:
   Source: 'src/demo.rs', lines 13:0-13:31 -/
def mul2_add1 (x : U32) : Result U32 :=
  do
  let i ← x + x
  i + 1#u32

/- [demo::use_mul2_add1]:
   Source: 'src/demo.rs', lines 17:0-17:43 -/
def use_mul2_add1 (x : U32) (y : U32) : Result U32 :=
  do
  let i ← mul2_add1 x
  i + y

/- [demo::incr]:
   Source: 'src/demo.rs', lines 21:0-21:31 -/
def incr (x : U32) : Result U32 :=
  x + 1#u32

/- [demo::use_incr]:
   Source: 'src/demo.rs', lines 25:0-25:17 -/
def use_incr : Result Unit :=
  do
  let i ← incr 0#u32
  let i1 ← incr i
  let _ ← incr i1
  Result.ret ()

/- [demo::CList]
   Source: 'src/demo.rs', lines 34:0-34:17 -/
inductive CList (T : Type) :=
| CCons : T → CList T → CList T
| CNil : CList T

/- [demo::list_nth]:
   Source: 'src/demo.rs', lines 39:0-39:56 -/
divergent def list_nth (T : Type) (l : CList T) (i : U32) : Result T :=
  match l with
  | CList.CCons x tl =>
    if i = 0#u32
    then Result.ret x
    else do
         let i1 ← i - 1#u32
         list_nth T tl i1
  | CList.CNil => Result.fail .panic

/- [demo::list_nth_mut]:
   Source: 'src/demo.rs', lines 54:0-54:68 -/
divergent def list_nth_mut
  (T : Type) (l : CList T) (i : U32) :
  Result (T × (T → Result (CList T)))
  :=
  match l with
  | CList.CCons x tl =>
    if i = 0#u32
    then
      let back_'a := fun ret => Result.ret (CList.CCons ret tl)
      Result.ret (x, back_'a)
    else
      do
      let i1 ← i - 1#u32
      let (t, list_nth_mut_back) ← list_nth_mut T tl i1
      let back_'a :=
        fun ret =>
          do
          let tl1 ← list_nth_mut_back ret
          Result.ret (CList.CCons x tl1)
      Result.ret (t, back_'a)
  | CList.CNil => Result.fail .panic

/- [demo::list_nth_mut1]: loop 0:
   Source: 'src/demo.rs', lines 69:0-78:1 -/
divergent def list_nth_mut1_loop
  (T : Type) (l : CList T) (i : U32) :
  Result (T × (T → Result (CList T)))
  :=
  match l with
  | CList.CCons x tl =>
    if i = 0#u32
    then
      let back_'a := fun ret => Result.ret (CList.CCons ret tl)
      Result.ret (x, back_'a)
    else
      do
      let i1 ← i - 1#u32
      let (t, back_'a) ← list_nth_mut1_loop T tl i1
      let back_'a1 :=
        fun ret => do
                   let tl1 ← back_'a ret
                   Result.ret (CList.CCons x tl1)
      Result.ret (t, back_'a1)
  | CList.CNil => Result.fail .panic

/- [demo::list_nth_mut1]:
   Source: 'src/demo.rs', lines 69:0-69:77 -/
def list_nth_mut1
  (T : Type) (l : CList T) (i : U32) :
  Result (T × (T → Result (CList T)))
  :=
  list_nth_mut1_loop T l i

/- [demo::i32_id]:
   Source: 'src/demo.rs', lines 80:0-80:28 -/
divergent def i32_id (i : I32) : Result I32 :=
  if i = 0#i32
  then Result.ret 0#i32
  else do
       let i1 ← i - 1#i32
       let i2 ← i32_id i1
       i2 + 1#i32

/- [demo::list_tail]:
   Source: 'src/demo.rs', lines 88:0-88:64 -/
divergent def list_tail
  (T : Type) (l : CList T) :
  Result ((CList T) × (CList T → Result (CList T)))
  :=
  match l with
  | CList.CCons t tl =>
    do
    let (c, list_tail_back) ← list_tail T tl
    let back_'a :=
      fun ret =>
        do
        let tl1 ← list_tail_back ret
        Result.ret (CList.CCons t tl1)
    Result.ret (c, back_'a)
  | CList.CNil => Result.ret (CList.CNil, Result.ret)

/- Trait declaration: [demo::Counter]
   Source: 'src/demo.rs', lines 97:0-97:17 -/
structure Counter (Self : Type) where
  incr : Self → Result (Usize × Self)

/- [demo::{(demo::Counter for usize)}::incr]:
   Source: 'src/demo.rs', lines 102:4-102:31 -/
def CounterUsize.incr (self : Usize) : Result (Usize × Usize) :=
  do
  let self1 ← self + 1#usize
  Result.ret (self, self1)

/- Trait implementation: [demo::{(demo::Counter for usize)}]
   Source: 'src/demo.rs', lines 101:0-101:22 -/
def CounterUsize : Counter Usize := {
  incr := CounterUsize.incr
}

/- [demo::use_counter]:
   Source: 'src/demo.rs', lines 109:0-109:59 -/
def use_counter
  (T : Type) (CounterInst : Counter T) (cnt : T) : Result (Usize × T) :=
  CounterInst.incr cnt

end demo
