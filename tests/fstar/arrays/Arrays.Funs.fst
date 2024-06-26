(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [arrays]: function definitions *)
module Arrays.Funs
open Primitives
include Arrays.Types
include Arrays.Clauses

#set-options "--z3rlimit 50 --fuel 1 --ifuel 1"

(** [arrays::incr]:
    Source: 'src/arrays.rs', lines 8:0-8:24 *)
let incr (x : u32) : result u32 =
  u32_add x 1

(** [arrays::array_to_shared_slice_]:
    Source: 'src/arrays.rs', lines 16:0-16:53 *)
let array_to_shared_slice_ (t : Type0) (s : array t 32) : result (slice t) =
  array_to_slice t 32 s

(** [arrays::array_to_mut_slice_]:
    Source: 'src/arrays.rs', lines 21:0-21:58 *)
let array_to_mut_slice_
  (t : Type0) (s : array t 32) :
  result ((slice t) & (slice t -> result (array t 32)))
  =
  array_to_slice_mut t 32 s

(** [arrays::array_len]:
    Source: 'src/arrays.rs', lines 25:0-25:40 *)
let array_len (t : Type0) (s : array t 32) : result usize =
  let* s1 = array_to_slice t 32 s in Ok (slice_len t s1)

(** [arrays::shared_array_len]:
    Source: 'src/arrays.rs', lines 29:0-29:48 *)
let shared_array_len (t : Type0) (s : array t 32) : result usize =
  let* s1 = array_to_slice t 32 s in Ok (slice_len t s1)

(** [arrays::shared_slice_len]:
    Source: 'src/arrays.rs', lines 33:0-33:44 *)
let shared_slice_len (t : Type0) (s : slice t) : result usize =
  Ok (slice_len t s)

(** [arrays::index_array_shared]:
    Source: 'src/arrays.rs', lines 37:0-37:57 *)
let index_array_shared (t : Type0) (s : array t 32) (i : usize) : result t =
  array_index_usize t 32 s i

(** [arrays::index_array_u32]:
    Source: 'src/arrays.rs', lines 44:0-44:53 *)
let index_array_u32 (s : array u32 32) (i : usize) : result u32 =
  array_index_usize u32 32 s i

(** [arrays::index_array_copy]:
    Source: 'src/arrays.rs', lines 48:0-48:45 *)
let index_array_copy (x : array u32 32) : result u32 =
  array_index_usize u32 32 x 0

(** [arrays::index_mut_array]:
    Source: 'src/arrays.rs', lines 52:0-52:62 *)
let index_mut_array
  (t : Type0) (s : array t 32) (i : usize) :
  result (t & (t -> result (array t 32)))
  =
  array_index_mut_usize t 32 s i

(** [arrays::index_slice]:
    Source: 'src/arrays.rs', lines 56:0-56:46 *)
let index_slice (t : Type0) (s : slice t) (i : usize) : result t =
  slice_index_usize t s i

(** [arrays::index_mut_slice]:
    Source: 'src/arrays.rs', lines 60:0-60:58 *)
let index_mut_slice
  (t : Type0) (s : slice t) (i : usize) :
  result (t & (t -> result (slice t)))
  =
  slice_index_mut_usize t s i

(** [arrays::slice_subslice_shared_]:
    Source: 'src/arrays.rs', lines 64:0-64:70 *)
let slice_subslice_shared_
  (x : slice u32) (y : usize) (z : usize) : result (slice u32) =
  core_slice_index_Slice_index u32 (core_ops_range_Range usize)
    (core_slice_index_SliceIndexRangeUsizeSliceTInst u32) x
    { start = y; end_ = z }

(** [arrays::slice_subslice_mut_]:
    Source: 'src/arrays.rs', lines 68:0-68:75 *)
let slice_subslice_mut_
  (x : slice u32) (y : usize) (z : usize) :
  result ((slice u32) & (slice u32 -> result (slice u32)))
  =
  let* (s, index_mut_back) =
    core_slice_index_Slice_index_mut u32 (core_ops_range_Range usize)
      (core_slice_index_SliceIndexRangeUsizeSliceTInst u32) x
      { start = y; end_ = z } in
  Ok (s, index_mut_back)

(** [arrays::array_to_slice_shared_]:
    Source: 'src/arrays.rs', lines 72:0-72:54 *)
let array_to_slice_shared_ (x : array u32 32) : result (slice u32) =
  array_to_slice u32 32 x

(** [arrays::array_to_slice_mut_]:
    Source: 'src/arrays.rs', lines 76:0-76:59 *)
let array_to_slice_mut_
  (x : array u32 32) :
  result ((slice u32) & (slice u32 -> result (array u32 32)))
  =
  array_to_slice_mut u32 32 x

(** [arrays::array_subslice_shared_]:
    Source: 'src/arrays.rs', lines 80:0-80:74 *)
let array_subslice_shared_
  (x : array u32 32) (y : usize) (z : usize) : result (slice u32) =
  core_array_Array_index u32 (core_ops_range_Range usize) 32
    (core_ops_index_IndexSliceTIInst u32 (core_ops_range_Range usize)
    (core_slice_index_SliceIndexRangeUsizeSliceTInst u32)) x
    { start = y; end_ = z }

(** [arrays::array_subslice_mut_]:
    Source: 'src/arrays.rs', lines 84:0-84:79 *)
let array_subslice_mut_
  (x : array u32 32) (y : usize) (z : usize) :
  result ((slice u32) & (slice u32 -> result (array u32 32)))
  =
  let* (s, index_mut_back) =
    core_array_Array_index_mut u32 (core_ops_range_Range usize) 32
      (core_ops_index_IndexMutSliceTIInst u32 (core_ops_range_Range usize)
      (core_slice_index_SliceIndexRangeUsizeSliceTInst u32)) x
      { start = y; end_ = z } in
  Ok (s, index_mut_back)

(** [arrays::index_slice_0]:
    Source: 'src/arrays.rs', lines 88:0-88:38 *)
let index_slice_0 (t : Type0) (s : slice t) : result t =
  slice_index_usize t s 0

(** [arrays::index_array_0]:
    Source: 'src/arrays.rs', lines 92:0-92:42 *)
let index_array_0 (t : Type0) (s : array t 32) : result t =
  array_index_usize t 32 s 0

(** [arrays::index_index_array]:
    Source: 'src/arrays.rs', lines 103:0-103:71 *)
let index_index_array
  (s : array (array u32 32) 32) (i : usize) (j : usize) : result u32 =
  let* a = array_index_usize (array u32 32) 32 s i in
  array_index_usize u32 32 a j

(** [arrays::update_update_array]:
    Source: 'src/arrays.rs', lines 114:0-114:70 *)
let update_update_array
  (s : array (array u32 32) 32) (i : usize) (j : usize) : result unit =
  let* (a, index_mut_back) = array_index_mut_usize (array u32 32) 32 s i in
  let* (_, index_mut_back1) = array_index_mut_usize u32 32 a j in
  let* a1 = index_mut_back1 0 in
  let* _ = index_mut_back a1 in
  Ok ()

(** [arrays::array_local_deep_copy]:
    Source: 'src/arrays.rs', lines 118:0-118:43 *)
let array_local_deep_copy (x : array u32 32) : result unit =
  Ok ()

(** [arrays::take_array]:
    Source: 'src/arrays.rs', lines 122:0-122:30 *)
let take_array (a : array u32 2) : result unit =
  Ok ()

(** [arrays::take_array_borrow]:
    Source: 'src/arrays.rs', lines 123:0-123:38 *)
let take_array_borrow (a : array u32 2) : result unit =
  Ok ()

(** [arrays::take_slice]:
    Source: 'src/arrays.rs', lines 124:0-124:28 *)
let take_slice (s : slice u32) : result unit =
  Ok ()

(** [arrays::take_mut_slice]:
    Source: 'src/arrays.rs', lines 125:0-125:36 *)
let take_mut_slice (s : slice u32) : result (slice u32) =
  Ok s

(** [arrays::const_array]:
    Source: 'src/arrays.rs', lines 127:0-127:32 *)
let const_array : result (array u32 2) =
  Ok (mk_array u32 2 [ 0; 0 ])

(** [arrays::const_slice]:
    Source: 'src/arrays.rs', lines 131:0-131:20 *)
let const_slice : result unit =
  let* _ = array_to_slice u32 2 (mk_array u32 2 [ 0; 0 ]) in Ok ()

(** [arrays::take_all]:
    Source: 'src/arrays.rs', lines 141:0-141:17 *)
let take_all : result unit =
  let* _ = take_array (mk_array u32 2 [ 0; 0 ]) in
  let* _ = take_array (mk_array u32 2 [ 0; 0 ]) in
  let* _ = take_array_borrow (mk_array u32 2 [ 0; 0 ]) in
  let* s = array_to_slice u32 2 (mk_array u32 2 [ 0; 0 ]) in
  let* _ = take_slice s in
  let* (s1, to_slice_mut_back) =
    array_to_slice_mut u32 2 (mk_array u32 2 [ 0; 0 ]) in
  let* s2 = take_mut_slice s1 in
  let* _ = to_slice_mut_back s2 in
  Ok ()

(** [arrays::index_array]:
    Source: 'src/arrays.rs', lines 155:0-155:38 *)
let index_array (x : array u32 2) : result u32 =
  array_index_usize u32 2 x 0

(** [arrays::index_array_borrow]:
    Source: 'src/arrays.rs', lines 158:0-158:46 *)
let index_array_borrow (x : array u32 2) : result u32 =
  array_index_usize u32 2 x 0

(** [arrays::index_slice_u32_0]:
    Source: 'src/arrays.rs', lines 162:0-162:42 *)
let index_slice_u32_0 (x : slice u32) : result u32 =
  slice_index_usize u32 x 0

(** [arrays::index_mut_slice_u32_0]:
    Source: 'src/arrays.rs', lines 166:0-166:50 *)
let index_mut_slice_u32_0 (x : slice u32) : result (u32 & (slice u32)) =
  let* i = slice_index_usize u32 x 0 in Ok (i, x)

(** [arrays::index_all]:
    Source: 'src/arrays.rs', lines 170:0-170:25 *)
let index_all : result u32 =
  let* i = index_array (mk_array u32 2 [ 0; 0 ]) in
  let* i1 = index_array (mk_array u32 2 [ 0; 0 ]) in
  let* i2 = u32_add i i1 in
  let* i3 = index_array_borrow (mk_array u32 2 [ 0; 0 ]) in
  let* i4 = u32_add i2 i3 in
  let* s = array_to_slice u32 2 (mk_array u32 2 [ 0; 0 ]) in
  let* i5 = index_slice_u32_0 s in
  let* i6 = u32_add i4 i5 in
  let* (s1, to_slice_mut_back) =
    array_to_slice_mut u32 2 (mk_array u32 2 [ 0; 0 ]) in
  let* (i7, s2) = index_mut_slice_u32_0 s1 in
  let* i8 = u32_add i6 i7 in
  let* _ = to_slice_mut_back s2 in
  Ok i8

(** [arrays::update_array]:
    Source: 'src/arrays.rs', lines 184:0-184:36 *)
let update_array (x : array u32 2) : result unit =
  let* (_, index_mut_back) = array_index_mut_usize u32 2 x 0 in
  let* _ = index_mut_back 1 in
  Ok ()

(** [arrays::update_array_mut_borrow]:
    Source: 'src/arrays.rs', lines 187:0-187:48 *)
let update_array_mut_borrow (x : array u32 2) : result (array u32 2) =
  let* (_, index_mut_back) = array_index_mut_usize u32 2 x 0 in
  index_mut_back 1

(** [arrays::update_mut_slice]:
    Source: 'src/arrays.rs', lines 190:0-190:38 *)
let update_mut_slice (x : slice u32) : result (slice u32) =
  let* (_, index_mut_back) = slice_index_mut_usize u32 x 0 in index_mut_back 1

(** [arrays::update_all]:
    Source: 'src/arrays.rs', lines 194:0-194:19 *)
let update_all : result unit =
  let* _ = update_array (mk_array u32 2 [ 0; 0 ]) in
  let* _ = update_array (mk_array u32 2 [ 0; 0 ]) in
  let* x = update_array_mut_borrow (mk_array u32 2 [ 0; 0 ]) in
  let* (s, to_slice_mut_back) = array_to_slice_mut u32 2 x in
  let* s1 = update_mut_slice s in
  let* _ = to_slice_mut_back s1 in
  Ok ()

(** [arrays::range_all]:
    Source: 'src/arrays.rs', lines 205:0-205:18 *)
let range_all : result unit =
  let* (s, index_mut_back) =
    core_array_Array_index_mut u32 (core_ops_range_Range usize) 4
      (core_ops_index_IndexMutSliceTIInst u32 (core_ops_range_Range usize)
      (core_slice_index_SliceIndexRangeUsizeSliceTInst u32))
      (mk_array u32 4 [ 0; 0; 0; 0 ]) { start = 1; end_ = 3 } in
  let* s1 = update_mut_slice s in
  let* _ = index_mut_back s1 in
  Ok ()

(** [arrays::deref_array_borrow]:
    Source: 'src/arrays.rs', lines 214:0-214:46 *)
let deref_array_borrow (x : array u32 2) : result u32 =
  array_index_usize u32 2 x 0

(** [arrays::deref_array_mut_borrow]:
    Source: 'src/arrays.rs', lines 219:0-219:54 *)
let deref_array_mut_borrow (x : array u32 2) : result (u32 & (array u32 2)) =
  let* i = array_index_usize u32 2 x 0 in Ok (i, x)

(** [arrays::take_array_t]:
    Source: 'src/arrays.rs', lines 227:0-227:31 *)
let take_array_t (a : array aB_t 2) : result unit =
  Ok ()

(** [arrays::non_copyable_array]:
    Source: 'src/arrays.rs', lines 229:0-229:27 *)
let non_copyable_array : result unit =
  take_array_t (mk_array aB_t 2 [ AB_A; AB_B ])

(** [arrays::sum]: loop 0:
    Source: 'src/arrays.rs', lines 242:0-250:1 *)
let rec sum_loop
  (s : slice u32) (sum1 : u32) (i : usize) :
  Tot (result u32) (decreases (sum_loop_decreases s sum1 i))
  =
  let i1 = slice_len u32 s in
  if i < i1
  then
    let* i2 = slice_index_usize u32 s i in
    let* sum3 = u32_add sum1 i2 in
    let* i3 = usize_add i 1 in
    sum_loop s sum3 i3
  else Ok sum1

(** [arrays::sum]:
    Source: 'src/arrays.rs', lines 242:0-242:28 *)
let sum (s : slice u32) : result u32 =
  sum_loop s 0 0

(** [arrays::sum2]: loop 0:
    Source: 'src/arrays.rs', lines 252:0-261:1 *)
let rec sum2_loop
  (s : slice u32) (s2 : slice u32) (sum1 : u32) (i : usize) :
  Tot (result u32) (decreases (sum2_loop_decreases s s2 sum1 i))
  =
  let i1 = slice_len u32 s in
  if i < i1
  then
    let* i2 = slice_index_usize u32 s i in
    let* i3 = slice_index_usize u32 s2 i in
    let* i4 = u32_add i2 i3 in
    let* sum3 = u32_add sum1 i4 in
    let* i5 = usize_add i 1 in
    sum2_loop s s2 sum3 i5
  else Ok sum1

(** [arrays::sum2]:
    Source: 'src/arrays.rs', lines 252:0-252:41 *)
let sum2 (s : slice u32) (s2 : slice u32) : result u32 =
  let i = slice_len u32 s in
  let i1 = slice_len u32 s2 in
  if not (i = i1) then Fail Failure else sum2_loop s s2 0 0

(** [arrays::f0]:
    Source: 'src/arrays.rs', lines 263:0-263:11 *)
let f0 : result unit =
  let* (s, to_slice_mut_back) =
    array_to_slice_mut u32 2 (mk_array u32 2 [ 1; 2 ]) in
  let* (_, index_mut_back) = slice_index_mut_usize u32 s 0 in
  let* s1 = index_mut_back 1 in
  let* _ = to_slice_mut_back s1 in
  Ok ()

(** [arrays::f1]:
    Source: 'src/arrays.rs', lines 268:0-268:11 *)
let f1 : result unit =
  let* (_, index_mut_back) =
    array_index_mut_usize u32 2 (mk_array u32 2 [ 1; 2 ]) 0 in
  let* _ = index_mut_back 1 in
  Ok ()

(** [arrays::f2]:
    Source: 'src/arrays.rs', lines 273:0-273:17 *)
let f2 (i : u32) : result unit =
  Ok ()

(** [arrays::f4]:
    Source: 'src/arrays.rs', lines 282:0-282:54 *)
let f4 (x : array u32 32) (y : usize) (z : usize) : result (slice u32) =
  core_array_Array_index u32 (core_ops_range_Range usize) 32
    (core_ops_index_IndexSliceTIInst u32 (core_ops_range_Range usize)
    (core_slice_index_SliceIndexRangeUsizeSliceTInst u32)) x
    { start = y; end_ = z }

(** [arrays::f3]:
    Source: 'src/arrays.rs', lines 275:0-275:18 *)
let f3 : result u32 =
  let* i = array_index_usize u32 2 (mk_array u32 2 [ 1; 2 ]) 0 in
  let* _ = f2 i in
  let b = array_repeat u32 32 0 in
  let* s = array_to_slice u32 2 (mk_array u32 2 [ 1; 2 ]) in
  let* s1 = f4 b 16 18 in
  sum2 s s1

(** [arrays::SZ]
    Source: 'src/arrays.rs', lines 286:0-286:19 *)
let sz_body : result usize = Ok 32
let sz : usize = eval_global sz_body

(** [arrays::f5]:
    Source: 'src/arrays.rs', lines 289:0-289:31 *)
let f5 (x : array u32 32) : result u32 =
  array_index_usize u32 32 x 0

(** [arrays::ite]:
    Source: 'src/arrays.rs', lines 294:0-294:12 *)
let ite : result unit =
  let* (s, to_slice_mut_back) =
    array_to_slice_mut u32 2 (mk_array u32 2 [ 0; 0 ]) in
  let* (_, s1) = index_mut_slice_u32_0 s in
  let* (s2, to_slice_mut_back1) =
    array_to_slice_mut u32 2 (mk_array u32 2 [ 0; 0 ]) in
  let* (_, s3) = index_mut_slice_u32_0 s2 in
  let* _ = to_slice_mut_back1 s3 in
  let* _ = to_slice_mut_back s1 in
  Ok ()

(** [arrays::zero_slice]: loop 0:
    Source: 'src/arrays.rs', lines 303:0-310:1 *)
let rec zero_slice_loop
  (a : slice u8) (i : usize) (len : usize) :
  Tot (result (slice u8)) (decreases (zero_slice_loop_decreases a i len))
  =
  if i < len
  then
    let* (_, index_mut_back) = slice_index_mut_usize u8 a i in
    let* i1 = usize_add i 1 in
    let* a1 = index_mut_back 0 in
    zero_slice_loop a1 i1 len
  else Ok a

(** [arrays::zero_slice]:
    Source: 'src/arrays.rs', lines 303:0-303:31 *)
let zero_slice (a : slice u8) : result (slice u8) =
  let len = slice_len u8 a in zero_slice_loop a 0 len

(** [arrays::iter_mut_slice]: loop 0:
    Source: 'src/arrays.rs', lines 312:0-318:1 *)
let rec iter_mut_slice_loop
  (len : usize) (i : usize) :
  Tot (result unit) (decreases (iter_mut_slice_loop_decreases len i))
  =
  if i < len
  then let* i1 = usize_add i 1 in iter_mut_slice_loop len i1
  else Ok ()

(** [arrays::iter_mut_slice]:
    Source: 'src/arrays.rs', lines 312:0-312:35 *)
let iter_mut_slice (a : slice u8) : result (slice u8) =
  let len = slice_len u8 a in let* _ = iter_mut_slice_loop len 0 in Ok a

(** [arrays::sum_mut_slice]: loop 0:
    Source: 'src/arrays.rs', lines 320:0-328:1 *)
let rec sum_mut_slice_loop
  (a : slice u32) (i : usize) (s : u32) :
  Tot (result u32) (decreases (sum_mut_slice_loop_decreases a i s))
  =
  let i1 = slice_len u32 a in
  if i < i1
  then
    let* i2 = slice_index_usize u32 a i in
    let* s1 = u32_add s i2 in
    let* i3 = usize_add i 1 in
    sum_mut_slice_loop a i3 s1
  else Ok s

(** [arrays::sum_mut_slice]:
    Source: 'src/arrays.rs', lines 320:0-320:42 *)
let sum_mut_slice (a : slice u32) : result (u32 & (slice u32)) =
  let* i = sum_mut_slice_loop a 0 0 in Ok (i, a)

