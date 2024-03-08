(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [loops]: function definitions *)
module Loops.Funs
open Primitives
include Loops.Types
include Loops.Clauses

#set-options "--z3rlimit 50 --fuel 1 --ifuel 1"

(** [loops::sum]: loop 0: forward function
    Source: 'src/loops.rs', lines 4:0-14:1 *)
let rec sum_loop
  (max : u32) (i : u32) (s : u32) :
  Tot (result u32) (decreases (sum_loop_decreases max i s))
  =
  if i < max
  then let* s1 = u32_add s i in let* i1 = u32_add i 1 in sum_loop max i1 s1
  else u32_mul s 2

(** [loops::sum]: forward function
    Source: 'src/loops.rs', lines 4:0-4:27 *)
let sum (max : u32) : result u32 =
  sum_loop max 0 0

(** [loops::sum_with_mut_borrows]: loop 0: forward function
    Source: 'src/loops.rs', lines 19:0-31:1 *)
let rec sum_with_mut_borrows_loop
  (max : u32) (mi : u32) (ms : u32) :
  Tot (result u32) (decreases (sum_with_mut_borrows_loop_decreases max mi ms))
  =
  if mi < max
  then
    let* ms1 = u32_add ms mi in
    let* mi1 = u32_add mi 1 in
    sum_with_mut_borrows_loop max mi1 ms1
  else u32_mul ms 2

(** [loops::sum_with_mut_borrows]: forward function
    Source: 'src/loops.rs', lines 19:0-19:44 *)
let sum_with_mut_borrows (max : u32) : result u32 =
  sum_with_mut_borrows_loop max 0 0

(** [loops::sum_with_shared_borrows]: loop 0: forward function
    Source: 'src/loops.rs', lines 34:0-48:1 *)
let rec sum_with_shared_borrows_loop
  (max : u32) (i : u32) (s : u32) :
  Tot (result u32) (decreases (sum_with_shared_borrows_loop_decreases max i s))
  =
  if i < max
  then
    let* i1 = u32_add i 1 in
    let* s1 = u32_add s i1 in
    sum_with_shared_borrows_loop max i1 s1
  else u32_mul s 2

(** [loops::sum_with_shared_borrows]: forward function
    Source: 'src/loops.rs', lines 34:0-34:47 *)
let sum_with_shared_borrows (max : u32) : result u32 =
  sum_with_shared_borrows_loop max 0 0

(** [loops::sum_array]: loop 0: forward function
    Source: 'src/loops.rs', lines 50:0-58:1 *)
let rec sum_array_loop
  (n : usize) (a : array u32 n) (i : usize) (s : u32) :
  Tot (result u32) (decreases (sum_array_loop_decreases n a i s))
  =
  if i < n
  then
    let* i1 = array_index_usize u32 n a i in
    let* s1 = u32_add s i1 in
    let* i2 = usize_add i 1 in
    sum_array_loop n a i2 s1
  else Return s

(** [loops::sum_array]: forward function
    Source: 'src/loops.rs', lines 50:0-50:52 *)
let sum_array (n : usize) (a : array u32 n) : result u32 =
  sum_array_loop n a 0 0

(** [loops::clear]: loop 0: merged forward/backward function
    (there is a single backward function, and the forward function returns ())
    Source: 'src/loops.rs', lines 62:0-68:1 *)
let rec clear_loop
  (v : alloc_vec_Vec u32) (i : usize) :
  Tot (result (alloc_vec_Vec u32)) (decreases (clear_loop_decreases v i))
  =
  let i1 = alloc_vec_Vec_len u32 v in
  if i < i1
  then
    let* i2 = usize_add i 1 in
    let* v1 =
      alloc_vec_Vec_index_mut_back u32 usize
        (core_slice_index_SliceIndexUsizeSliceTInst u32) v i 0 in
    clear_loop v1 i2
  else Return v

(** [loops::clear]: merged forward/backward function
    (there is a single backward function, and the forward function returns ())
    Source: 'src/loops.rs', lines 62:0-62:30 *)
let clear (v : alloc_vec_Vec u32) : result (alloc_vec_Vec u32) =
  clear_loop v 0

(** [loops::list_mem]: loop 0: forward function
    Source: 'src/loops.rs', lines 76:0-85:1 *)
let rec list_mem_loop
  (x : u32) (ls : list_t u32) :
  Tot (result bool) (decreases (list_mem_loop_decreases x ls))
  =
  begin match ls with
  | List_Cons y tl -> if y = x then Return true else list_mem_loop x tl
  | List_Nil -> Return false
  end

(** [loops::list_mem]: forward function
    Source: 'src/loops.rs', lines 76:0-76:52 *)
let list_mem (x : u32) (ls : list_t u32) : result bool =
  list_mem_loop x ls

(** [loops::list_nth_mut_loop]: loop 0: forward function
    Source: 'src/loops.rs', lines 88:0-98:1 *)
let rec list_nth_mut_loop_loop
  (t : Type0) (ls : list_t t) (i : u32) :
  Tot (result t) (decreases (list_nth_mut_loop_loop_decreases t ls i))
  =
  begin match ls with
  | List_Cons x tl ->
    if i = 0
    then Return x
    else let* i1 = u32_sub i 1 in list_nth_mut_loop_loop t tl i1
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_loop]: forward function
    Source: 'src/loops.rs', lines 88:0-88:71 *)
let list_nth_mut_loop (t : Type0) (ls : list_t t) (i : u32) : result t =
  list_nth_mut_loop_loop t ls i

(** [loops::list_nth_mut_loop]: loop 0: backward function 0
    Source: 'src/loops.rs', lines 88:0-98:1 *)
let rec list_nth_mut_loop_loop_back
  (t : Type0) (ls : list_t t) (i : u32) (ret : t) :
  Tot (result (list_t t)) (decreases (list_nth_mut_loop_loop_decreases t ls i))
  =
  begin match ls with
  | List_Cons x tl ->
    if i = 0
    then Return (List_Cons ret tl)
    else
      let* i1 = u32_sub i 1 in
      let* tl1 = list_nth_mut_loop_loop_back t tl i1 ret in
      Return (List_Cons x tl1)
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_loop]: backward function 0
    Source: 'src/loops.rs', lines 88:0-88:71 *)
let list_nth_mut_loop_back
  (t : Type0) (ls : list_t t) (i : u32) (ret : t) : result (list_t t) =
  list_nth_mut_loop_loop_back t ls i ret

(** [loops::list_nth_shared_loop]: loop 0: forward function
    Source: 'src/loops.rs', lines 101:0-111:1 *)
let rec list_nth_shared_loop_loop
  (t : Type0) (ls : list_t t) (i : u32) :
  Tot (result t) (decreases (list_nth_shared_loop_loop_decreases t ls i))
  =
  begin match ls with
  | List_Cons x tl ->
    if i = 0
    then Return x
    else let* i1 = u32_sub i 1 in list_nth_shared_loop_loop t tl i1
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_shared_loop]: forward function
    Source: 'src/loops.rs', lines 101:0-101:66 *)
let list_nth_shared_loop (t : Type0) (ls : list_t t) (i : u32) : result t =
  list_nth_shared_loop_loop t ls i

(** [loops::get_elem_mut]: loop 0: forward function
    Source: 'src/loops.rs', lines 113:0-127:1 *)
let rec get_elem_mut_loop
  (x : usize) (ls : list_t usize) :
  Tot (result usize) (decreases (get_elem_mut_loop_decreases x ls))
  =
  begin match ls with
  | List_Cons y tl -> if y = x then Return y else get_elem_mut_loop x tl
  | List_Nil -> Fail Failure
  end

(** [loops::get_elem_mut]: forward function
    Source: 'src/loops.rs', lines 113:0-113:73 *)
let get_elem_mut
  (slots : alloc_vec_Vec (list_t usize)) (x : usize) : result usize =
  let* l =
    alloc_vec_Vec_index_mut (list_t usize) usize
      (core_slice_index_SliceIndexUsizeSliceTInst (list_t usize)) slots 0 in
  get_elem_mut_loop x l

(** [loops::get_elem_mut]: loop 0: backward function 0
    Source: 'src/loops.rs', lines 113:0-127:1 *)
let rec get_elem_mut_loop_back
  (x : usize) (ls : list_t usize) (ret : usize) :
  Tot (result (list_t usize)) (decreases (get_elem_mut_loop_decreases x ls))
  =
  begin match ls with
  | List_Cons y tl ->
    if y = x
    then Return (List_Cons ret tl)
    else let* tl1 = get_elem_mut_loop_back x tl ret in Return (List_Cons y tl1)
  | List_Nil -> Fail Failure
  end

(** [loops::get_elem_mut]: backward function 0
    Source: 'src/loops.rs', lines 113:0-113:73 *)
let get_elem_mut_back
  (slots : alloc_vec_Vec (list_t usize)) (x : usize) (ret : usize) :
  result (alloc_vec_Vec (list_t usize))
  =
  let* l =
    alloc_vec_Vec_index_mut (list_t usize) usize
      (core_slice_index_SliceIndexUsizeSliceTInst (list_t usize)) slots 0 in
  let* l1 = get_elem_mut_loop_back x l ret in
  alloc_vec_Vec_index_mut_back (list_t usize) usize
    (core_slice_index_SliceIndexUsizeSliceTInst (list_t usize)) slots 0 l1

(** [loops::get_elem_shared]: loop 0: forward function
    Source: 'src/loops.rs', lines 129:0-143:1 *)
let rec get_elem_shared_loop
  (x : usize) (ls : list_t usize) :
  Tot (result usize) (decreases (get_elem_shared_loop_decreases x ls))
  =
  begin match ls with
  | List_Cons y tl -> if y = x then Return y else get_elem_shared_loop x tl
  | List_Nil -> Fail Failure
  end

(** [loops::get_elem_shared]: forward function
    Source: 'src/loops.rs', lines 129:0-129:68 *)
let get_elem_shared
  (slots : alloc_vec_Vec (list_t usize)) (x : usize) : result usize =
  let* l =
    alloc_vec_Vec_index (list_t usize) usize
      (core_slice_index_SliceIndexUsizeSliceTInst (list_t usize)) slots 0 in
  get_elem_shared_loop x l

(** [loops::id_mut]: forward function
    Source: 'src/loops.rs', lines 145:0-145:50 *)
let id_mut (t : Type0) (ls : list_t t) : result (list_t t) =
  Return ls

(** [loops::id_mut]: backward function 0
    Source: 'src/loops.rs', lines 145:0-145:50 *)
let id_mut_back
  (t : Type0) (ls : list_t t) (ret : list_t t) : result (list_t t) =
  Return ret

(** [loops::id_shared]: forward function
    Source: 'src/loops.rs', lines 149:0-149:45 *)
let id_shared (t : Type0) (ls : list_t t) : result (list_t t) =
  Return ls

(** [loops::list_nth_mut_loop_with_id]: loop 0: forward function
    Source: 'src/loops.rs', lines 154:0-165:1 *)
let rec list_nth_mut_loop_with_id_loop
  (t : Type0) (i : u32) (ls : list_t t) :
  Tot (result t) (decreases (list_nth_mut_loop_with_id_loop_decreases t i ls))
  =
  begin match ls with
  | List_Cons x tl ->
    if i = 0
    then Return x
    else let* i1 = u32_sub i 1 in list_nth_mut_loop_with_id_loop t i1 tl
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_loop_with_id]: forward function
    Source: 'src/loops.rs', lines 154:0-154:75 *)
let list_nth_mut_loop_with_id
  (t : Type0) (ls : list_t t) (i : u32) : result t =
  let* ls1 = id_mut t ls in list_nth_mut_loop_with_id_loop t i ls1

(** [loops::list_nth_mut_loop_with_id]: loop 0: backward function 0
    Source: 'src/loops.rs', lines 154:0-165:1 *)
let rec list_nth_mut_loop_with_id_loop_back
  (t : Type0) (i : u32) (ls : list_t t) (ret : t) :
  Tot (result (list_t t))
  (decreases (list_nth_mut_loop_with_id_loop_decreases t i ls))
  =
  begin match ls with
  | List_Cons x tl ->
    if i = 0
    then Return (List_Cons ret tl)
    else
      let* i1 = u32_sub i 1 in
      let* tl1 = list_nth_mut_loop_with_id_loop_back t i1 tl ret in
      Return (List_Cons x tl1)
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_loop_with_id]: backward function 0
    Source: 'src/loops.rs', lines 154:0-154:75 *)
let list_nth_mut_loop_with_id_back
  (t : Type0) (ls : list_t t) (i : u32) (ret : t) : result (list_t t) =
  let* ls1 = id_mut t ls in
  let* l = list_nth_mut_loop_with_id_loop_back t i ls1 ret in
  id_mut_back t ls l

(** [loops::list_nth_shared_loop_with_id]: loop 0: forward function
    Source: 'src/loops.rs', lines 168:0-179:1 *)
let rec list_nth_shared_loop_with_id_loop
  (t : Type0) (i : u32) (ls : list_t t) :
  Tot (result t)
  (decreases (list_nth_shared_loop_with_id_loop_decreases t i ls))
  =
  begin match ls with
  | List_Cons x tl ->
    if i = 0
    then Return x
    else let* i1 = u32_sub i 1 in list_nth_shared_loop_with_id_loop t i1 tl
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_shared_loop_with_id]: forward function
    Source: 'src/loops.rs', lines 168:0-168:70 *)
let list_nth_shared_loop_with_id
  (t : Type0) (ls : list_t t) (i : u32) : result t =
  let* ls1 = id_shared t ls in list_nth_shared_loop_with_id_loop t i ls1

(** [loops::list_nth_mut_loop_pair]: loop 0: forward function
    Source: 'src/loops.rs', lines 184:0-205:1 *)
let rec list_nth_mut_loop_pair_loop
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) :
  Tot (result (t & t))
  (decreases (list_nth_mut_loop_pair_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (x0, x1)
      else let* i1 = u32_sub i 1 in list_nth_mut_loop_pair_loop t tl0 tl1 i1
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_loop_pair]: forward function
    Source: 'src/loops.rs', lines 184:0-188:27 *)
let list_nth_mut_loop_pair
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) : result (t & t) =
  list_nth_mut_loop_pair_loop t ls0 ls1 i

(** [loops::list_nth_mut_loop_pair]: loop 0: backward function 0
    Source: 'src/loops.rs', lines 184:0-205:1 *)
let rec list_nth_mut_loop_pair_loop_back'a
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  Tot (result (list_t t))
  (decreases (list_nth_mut_loop_pair_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons _ tl1 ->
      if i = 0
      then Return (List_Cons ret tl0)
      else
        let* i1 = u32_sub i 1 in
        let* tl01 = list_nth_mut_loop_pair_loop_back'a t tl0 tl1 i1 ret in
        Return (List_Cons x0 tl01)
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_loop_pair]: backward function 0
    Source: 'src/loops.rs', lines 184:0-188:27 *)
let list_nth_mut_loop_pair_back'a
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  result (list_t t)
  =
  list_nth_mut_loop_pair_loop_back'a t ls0 ls1 i ret

(** [loops::list_nth_mut_loop_pair]: loop 0: backward function 1
    Source: 'src/loops.rs', lines 184:0-205:1 *)
let rec list_nth_mut_loop_pair_loop_back'b
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  Tot (result (list_t t))
  (decreases (list_nth_mut_loop_pair_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons _ tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (List_Cons ret tl1)
      else
        let* i1 = u32_sub i 1 in
        let* tl11 = list_nth_mut_loop_pair_loop_back'b t tl0 tl1 i1 ret in
        Return (List_Cons x1 tl11)
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_loop_pair]: backward function 1
    Source: 'src/loops.rs', lines 184:0-188:27 *)
let list_nth_mut_loop_pair_back'b
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  result (list_t t)
  =
  list_nth_mut_loop_pair_loop_back'b t ls0 ls1 i ret

(** [loops::list_nth_shared_loop_pair]: loop 0: forward function
    Source: 'src/loops.rs', lines 208:0-229:1 *)
let rec list_nth_shared_loop_pair_loop
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) :
  Tot (result (t & t))
  (decreases (list_nth_shared_loop_pair_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (x0, x1)
      else let* i1 = u32_sub i 1 in list_nth_shared_loop_pair_loop t tl0 tl1 i1
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_shared_loop_pair]: forward function
    Source: 'src/loops.rs', lines 208:0-212:19 *)
let list_nth_shared_loop_pair
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) : result (t & t) =
  list_nth_shared_loop_pair_loop t ls0 ls1 i

(** [loops::list_nth_mut_loop_pair_merge]: loop 0: forward function
    Source: 'src/loops.rs', lines 233:0-248:1 *)
let rec list_nth_mut_loop_pair_merge_loop
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) :
  Tot (result (t & t))
  (decreases (list_nth_mut_loop_pair_merge_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (x0, x1)
      else
        let* i1 = u32_sub i 1 in list_nth_mut_loop_pair_merge_loop t tl0 tl1 i1
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_loop_pair_merge]: forward function
    Source: 'src/loops.rs', lines 233:0-237:27 *)
let list_nth_mut_loop_pair_merge
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) : result (t & t) =
  list_nth_mut_loop_pair_merge_loop t ls0 ls1 i

(** [loops::list_nth_mut_loop_pair_merge]: loop 0: backward function 0
    Source: 'src/loops.rs', lines 233:0-248:1 *)
let rec list_nth_mut_loop_pair_merge_loop_back
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : (t & t)) :
  Tot (result ((list_t t) & (list_t t)))
  (decreases (list_nth_mut_loop_pair_merge_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then let (x, x2) = ret in Return (List_Cons x tl0, List_Cons x2 tl1)
      else
        let* i1 = u32_sub i 1 in
        let* (tl01, tl11) =
          list_nth_mut_loop_pair_merge_loop_back t tl0 tl1 i1 ret in
        Return (List_Cons x0 tl01, List_Cons x1 tl11)
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_loop_pair_merge]: backward function 0
    Source: 'src/loops.rs', lines 233:0-237:27 *)
let list_nth_mut_loop_pair_merge_back
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : (t & t)) :
  result ((list_t t) & (list_t t))
  =
  list_nth_mut_loop_pair_merge_loop_back t ls0 ls1 i ret

(** [loops::list_nth_shared_loop_pair_merge]: loop 0: forward function
    Source: 'src/loops.rs', lines 251:0-266:1 *)
let rec list_nth_shared_loop_pair_merge_loop
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) :
  Tot (result (t & t))
  (decreases (list_nth_shared_loop_pair_merge_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (x0, x1)
      else
        let* i1 = u32_sub i 1 in
        list_nth_shared_loop_pair_merge_loop t tl0 tl1 i1
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_shared_loop_pair_merge]: forward function
    Source: 'src/loops.rs', lines 251:0-255:19 *)
let list_nth_shared_loop_pair_merge
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) : result (t & t) =
  list_nth_shared_loop_pair_merge_loop t ls0 ls1 i

(** [loops::list_nth_mut_shared_loop_pair]: loop 0: forward function
    Source: 'src/loops.rs', lines 269:0-284:1 *)
let rec list_nth_mut_shared_loop_pair_loop
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) :
  Tot (result (t & t))
  (decreases (list_nth_mut_shared_loop_pair_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (x0, x1)
      else
        let* i1 = u32_sub i 1 in
        list_nth_mut_shared_loop_pair_loop t tl0 tl1 i1
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_shared_loop_pair]: forward function
    Source: 'src/loops.rs', lines 269:0-273:23 *)
let list_nth_mut_shared_loop_pair
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) : result (t & t) =
  list_nth_mut_shared_loop_pair_loop t ls0 ls1 i

(** [loops::list_nth_mut_shared_loop_pair]: loop 0: backward function 0
    Source: 'src/loops.rs', lines 269:0-284:1 *)
let rec list_nth_mut_shared_loop_pair_loop_back
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  Tot (result (list_t t))
  (decreases (list_nth_mut_shared_loop_pair_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons _ tl1 ->
      if i = 0
      then Return (List_Cons ret tl0)
      else
        let* i1 = u32_sub i 1 in
        let* tl01 = list_nth_mut_shared_loop_pair_loop_back t tl0 tl1 i1 ret in
        Return (List_Cons x0 tl01)
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_shared_loop_pair]: backward function 0
    Source: 'src/loops.rs', lines 269:0-273:23 *)
let list_nth_mut_shared_loop_pair_back
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  result (list_t t)
  =
  list_nth_mut_shared_loop_pair_loop_back t ls0 ls1 i ret

(** [loops::list_nth_mut_shared_loop_pair_merge]: loop 0: forward function
    Source: 'src/loops.rs', lines 288:0-303:1 *)
let rec list_nth_mut_shared_loop_pair_merge_loop
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) :
  Tot (result (t & t))
  (decreases (list_nth_mut_shared_loop_pair_merge_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (x0, x1)
      else
        let* i1 = u32_sub i 1 in
        list_nth_mut_shared_loop_pair_merge_loop t tl0 tl1 i1
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_shared_loop_pair_merge]: forward function
    Source: 'src/loops.rs', lines 288:0-292:23 *)
let list_nth_mut_shared_loop_pair_merge
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) : result (t & t) =
  list_nth_mut_shared_loop_pair_merge_loop t ls0 ls1 i

(** [loops::list_nth_mut_shared_loop_pair_merge]: loop 0: backward function 0
    Source: 'src/loops.rs', lines 288:0-303:1 *)
let rec list_nth_mut_shared_loop_pair_merge_loop_back
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  Tot (result (list_t t))
  (decreases (list_nth_mut_shared_loop_pair_merge_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons _ tl1 ->
      if i = 0
      then Return (List_Cons ret tl0)
      else
        let* i1 = u32_sub i 1 in
        let* tl01 =
          list_nth_mut_shared_loop_pair_merge_loop_back t tl0 tl1 i1 ret in
        Return (List_Cons x0 tl01)
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_mut_shared_loop_pair_merge]: backward function 0
    Source: 'src/loops.rs', lines 288:0-292:23 *)
let list_nth_mut_shared_loop_pair_merge_back
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  result (list_t t)
  =
  list_nth_mut_shared_loop_pair_merge_loop_back t ls0 ls1 i ret

(** [loops::list_nth_shared_mut_loop_pair]: loop 0: forward function
    Source: 'src/loops.rs', lines 307:0-322:1 *)
let rec list_nth_shared_mut_loop_pair_loop
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) :
  Tot (result (t & t))
  (decreases (list_nth_shared_mut_loop_pair_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (x0, x1)
      else
        let* i1 = u32_sub i 1 in
        list_nth_shared_mut_loop_pair_loop t tl0 tl1 i1
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_shared_mut_loop_pair]: forward function
    Source: 'src/loops.rs', lines 307:0-311:23 *)
let list_nth_shared_mut_loop_pair
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) : result (t & t) =
  list_nth_shared_mut_loop_pair_loop t ls0 ls1 i

(** [loops::list_nth_shared_mut_loop_pair]: loop 0: backward function 1
    Source: 'src/loops.rs', lines 307:0-322:1 *)
let rec list_nth_shared_mut_loop_pair_loop_back
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  Tot (result (list_t t))
  (decreases (list_nth_shared_mut_loop_pair_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons _ tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (List_Cons ret tl1)
      else
        let* i1 = u32_sub i 1 in
        let* tl11 = list_nth_shared_mut_loop_pair_loop_back t tl0 tl1 i1 ret in
        Return (List_Cons x1 tl11)
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_shared_mut_loop_pair]: backward function 1
    Source: 'src/loops.rs', lines 307:0-311:23 *)
let list_nth_shared_mut_loop_pair_back
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  result (list_t t)
  =
  list_nth_shared_mut_loop_pair_loop_back t ls0 ls1 i ret

(** [loops::list_nth_shared_mut_loop_pair_merge]: loop 0: forward function
    Source: 'src/loops.rs', lines 326:0-341:1 *)
let rec list_nth_shared_mut_loop_pair_merge_loop
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) :
  Tot (result (t & t))
  (decreases (list_nth_shared_mut_loop_pair_merge_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons x0 tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (x0, x1)
      else
        let* i1 = u32_sub i 1 in
        list_nth_shared_mut_loop_pair_merge_loop t tl0 tl1 i1
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_shared_mut_loop_pair_merge]: forward function
    Source: 'src/loops.rs', lines 326:0-330:23 *)
let list_nth_shared_mut_loop_pair_merge
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) : result (t & t) =
  list_nth_shared_mut_loop_pair_merge_loop t ls0 ls1 i

(** [loops::list_nth_shared_mut_loop_pair_merge]: loop 0: backward function 0
    Source: 'src/loops.rs', lines 326:0-341:1 *)
let rec list_nth_shared_mut_loop_pair_merge_loop_back
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  Tot (result (list_t t))
  (decreases (list_nth_shared_mut_loop_pair_merge_loop_decreases t ls0 ls1 i))
  =
  begin match ls0 with
  | List_Cons _ tl0 ->
    begin match ls1 with
    | List_Cons x1 tl1 ->
      if i = 0
      then Return (List_Cons ret tl1)
      else
        let* i1 = u32_sub i 1 in
        let* tl11 =
          list_nth_shared_mut_loop_pair_merge_loop_back t tl0 tl1 i1 ret in
        Return (List_Cons x1 tl11)
    | List_Nil -> Fail Failure
    end
  | List_Nil -> Fail Failure
  end

(** [loops::list_nth_shared_mut_loop_pair_merge]: backward function 0
    Source: 'src/loops.rs', lines 326:0-330:23 *)
let list_nth_shared_mut_loop_pair_merge_back
  (t : Type0) (ls0 : list_t t) (ls1 : list_t t) (i : u32) (ret : t) :
  result (list_t t)
  =
  list_nth_shared_mut_loop_pair_merge_loop_back t ls0 ls1 i ret
