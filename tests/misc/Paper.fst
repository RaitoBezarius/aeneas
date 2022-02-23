(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [paper] *)
module Paper
open Primitives

#set-options "--z3rlimit 50 --fuel 0 --ifuel 1"

(** [paper::ref_incr] *)
let ref_incr_fwd_back (x : i32) : result i32 =
  begin match i32_add x 1 with | Fail -> Fail | Return x0 -> Return x0 end

(** [paper::test_incr] *)
let test_incr_fwd : result unit =
  begin match ref_incr_fwd_back 0 with
  | Fail -> Fail
  | Return i -> if not (i = 1) then Fail else Return ()
  end

(** Unit test for [paper::test_incr] *)
let _ = assert_norm (test_incr_fwd = Return ())

(** [paper::choose] *)
let choose_fwd (t : Type0) (b : bool) (x : t) (y : t) : result t =
  if b then Return x else Return y

(** [paper::choose] *)
let choose_back
  (t : Type0) (b : bool) (x : t) (y : t) (ret : t) : result (t & t) =
  if b then Return (ret, y) else Return (x, ret)

(** [paper::test_choose] *)
let test_choose_fwd : result unit =
  begin match choose_fwd i32 true 0 0 with
  | Fail -> Fail
  | Return i ->
    begin match i32_add i 1 with
    | Fail -> Fail
    | Return z ->
      if not (z = 1)
      then Fail
      else
        begin match choose_back i32 true 0 0 z with
        | Fail -> Fail
        | Return (i0, i1) ->
          if not (i0 = 1)
          then Fail
          else if not (i1 = 0) then Fail else Return ()
        end
    end
  end

(** Unit test for [paper::test_choose] *)
let _ = assert_norm (test_choose_fwd = Return ())

(** [paper::List] *)
type list_t (t : Type0) =
| ListCons : t -> list_t t -> list_t t
| ListNil : list_t t

(** [paper::list_nth_mut] *)
let rec list_nth_mut_fwd (t : Type0) (l : list_t t) (i : u32) : result t =
  begin match l with
  | ListCons x tl ->
    begin match i with
    | 0 -> Return x
    | _ ->
      begin match u32_sub i 1 with
      | Fail -> Fail
      | Return i0 ->
        begin match list_nth_mut_fwd t tl i0 with
        | Fail -> Fail
        | Return x0 -> Return x0
        end
      end
    end
  | ListNil -> Fail
  end

(** [paper::list_nth_mut] *)
let rec list_nth_mut_back
  (t : Type0) (l : list_t t) (i : u32) (ret : t) : result (list_t t) =
  begin match l with
  | ListCons x tl ->
    begin match i with
    | 0 -> Return (ListCons ret tl)
    | _ ->
      begin match u32_sub i 1 with
      | Fail -> Fail
      | Return i0 ->
        begin match list_nth_mut_back t tl i0 ret with
        | Fail -> Fail
        | Return l0 -> Return (ListCons x l0)
        end
      end
    end
  | ListNil -> Fail
  end

(** [paper::sum] *)
let rec sum_fwd (l : list_t i32) : result i32 =
  begin match l with
  | ListCons x tl ->
    begin match sum_fwd tl with
    | Fail -> Fail
    | Return i ->
      begin match i32_add x i with | Fail -> Fail | Return i0 -> Return i0 end
    end
  | ListNil -> Return 0
  end

(** [paper::test_nth] *)
let test_nth_fwd : result unit =
  let l = ListNil in
  let l0 = ListCons 3 l in
  let l1 = ListCons 2 l0 in
  begin match list_nth_mut_fwd i32 (ListCons 1 l1) 2 with
  | Fail -> Fail
  | Return i ->
    begin match i32_add i 1 with
    | Fail -> Fail
    | Return x ->
      begin match list_nth_mut_back i32 (ListCons 1 l1) 2 x with
      | Fail -> Fail
      | Return l2 ->
        begin match sum_fwd l2 with
        | Fail -> Fail
        | Return i0 -> if not (i0 = 7) then Fail else Return ()
        end
      end
    end
  end

(** Unit test for [paper::test_nth] *)
let _ = assert_norm (test_nth_fwd = Return ())

