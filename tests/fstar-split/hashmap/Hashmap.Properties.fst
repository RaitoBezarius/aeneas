(** Properties about the hashmap *)
module Hashmap.Properties
open Primitives
open FStar.List.Tot
open FStar.Mul
open Hashmap.Types
open Hashmap.Clauses
open Hashmap.Funs

#set-options "--z3rlimit 50 --fuel 0 --ifuel 1"

let _align_fsti = ()

/// The proofs:
/// ===========
/// 
/// The proof strategy is to do exactly as with Low* proofs (we initially tried to
/// prove more properties in one go, but it was a mistake):
/// - prove that, under some preconditions, the low-level functions translated
///   from Rust refine some higher-level functions
/// - do functional proofs about those high-level functions to prove interesting
///   properties about the hash map operations, and invariant preservation
/// - combine everything
///
/// The fact that we work in a pure setting allows us to be more modular than when
/// working with effects. For instance we can do a case disjunction (see the proofs
/// for insert, which study the cases where the key is already/not in the hash map
/// in separate proofs - we had initially tried to do them in one step: it is doable
/// but requires some work, and the F* response time quickly becomes annoying while
/// making progress, so we split them). We can also easily prove a refinement lemma,
/// study the model, *then* combine those to also prove that the low-level function
/// preserves the invariants, rather than do everything at once as is usually the
/// case when doing intrinsic proofs with effects (I remember that having to prove
/// invariants in one go *and* a refinement step, even small, can be extremely
/// difficult in Low*).


(*** Utilities *)

/// We need many small helpers and lemmas, mostly about lists (and the ones we list
/// here are not in the standard F* library).

val index_append_lem (#a : Type0) (ls0 ls1 : list a) (i : nat{i < length ls0 + length ls1}) :
  Lemma (
    (i < length ls0 ==> index (ls0 @ ls1) i == index ls0 i) /\
    (i >= length ls0 ==> index (ls0 @ ls1) i == index ls1 (i - length ls0)))
  [SMTPat (index (ls0 @ ls1) i)]

#push-options "--fuel 1"
let rec index_append_lem #a ls0 ls1 i =
  match ls0 with
  | [] -> ()
  | x :: ls0' ->
    if i = 0 then ()
    else index_append_lem ls0' ls1 (i-1)
#pop-options

val index_map_lem (#a #b: Type0) (f : a -> Tot b) (ls : list a)
  (i : nat{i < length ls}) :
  Lemma (
    index (map f ls) i == f (index ls i))
  [SMTPat (index (map f ls) i)]

#push-options "--fuel 1"
let rec index_map_lem #a #b f ls i =
  match ls with
  | [] -> ()
  | x :: ls' ->
    if i = 0 then ()
    else index_map_lem f ls' (i-1)
#pop-options

val for_all_append (#a : Type0) (f : a -> Tot bool) (ls0 ls1 : list a) :
  Lemma (for_all f (ls0 @ ls1) = (for_all f ls0 && for_all f ls1))

#push-options "--fuel 1"
let rec for_all_append #a f ls0 ls1 =
  match ls0 with
  | [] -> ()
  | x :: ls0' ->
    for_all_append f ls0' ls1
#pop-options

/// Filter a list, stopping after we removed one element
val filter_one (#a : Type) (f : a -> bool) (ls : list a) : list a

let rec filter_one #a f ls =
  match ls with
  | [] -> []
  | x :: ls' -> if f x then x :: filter_one f ls' else ls'

val find_append (#a : Type) (f : a -> bool) (ls0 ls1 : list a) :
  Lemma (
    find f (ls0 @ ls1) ==
    begin match find f ls0 with
    | Some x -> Some x
    | None -> find f ls1
    end)

#push-options "--fuel 1"
let rec find_append #a f ls0 ls1 =
  match ls0 with
  | [] -> ()
  | x :: ls0' ->
    if f x then
    begin
      assert(ls0 @ ls1 == x :: (ls0' @ ls1));
      assert(find f (ls0 @ ls1) == find f (x :: (ls0' @ ls1)));
      // Why do I have to do this?! Is it because of subtyping??
      assert(
        match find f (ls0 @ ls1) with
        | Some x' -> x' == x
        | None -> False)
    end
    else find_append f ls0' ls1
#pop-options

val length_flatten_update :
     #a:Type
  -> ls:list (list a)
  -> i:nat{i < length ls}
  -> x:list a ->
  Lemma (
    // We want this property:
    // ```
    // length (flatten (list_update ls i x)) =
    //   length (flatten ls) - length (index ls i) + length x
    // ```
    length (flatten (list_update ls i x)) + length (index ls i) =
    length (flatten ls) + length x)

#push-options "--fuel 1"
let rec length_flatten_update #a ls i x =
  match ls with
  | x' :: ls' ->
    assert(flatten ls == x' @ flatten ls'); // Triggers patterns
    assert(length (flatten ls) == length x' + length (flatten ls'));
    if i = 0 then
      begin
      let ls1 = x :: ls' in
      assert(list_update ls i x == ls1);
      assert(flatten ls1 == x @ flatten ls'); // Triggers patterns
      assert(length (flatten ls1) == length x + length (flatten ls'));
      ()
      end
    else
      begin
      length_flatten_update ls' (i-1) x;
      let ls1 = x' :: list_update ls' (i-1) x in
      assert(flatten ls1 == x' @ flatten (list_update ls' (i-1) x)) // Triggers patterns
      end
#pop-options

val length_flatten_index :
     #a:Type
  -> ls:list (list a)
  -> i:nat{i < length ls} ->
  Lemma (
    length (flatten ls) >= length (index ls i))

#push-options "--fuel 1"
let rec length_flatten_index #a ls i =
  match ls with
  | x' :: ls' ->
    assert(flatten ls == x' @ flatten ls'); // Triggers patterns
    assert(length (flatten ls) == length x' + length (flatten ls'));
    if i = 0 then ()
    else length_flatten_index ls' (i-1)
#pop-options

val forall_index_equiv_list_for_all
  (#a : Type) (pred : a -> Tot bool) (ls : list a) :
  Lemma ((forall (i:nat{i < length ls}). pred (index ls i)) <==> for_all pred ls)

#push-options "--fuel 1"
let rec forall_index_equiv_list_for_all pred ls =
  match ls with
  | [] -> ()
  | x :: ls' ->
    assert(forall (i:nat{i < length ls'}). index ls' i == index ls (i+1));
    assert(forall (i:nat{0 < i /\ i < length ls}). index ls i == index ls' (i-1));
    assert(index ls 0 == x);
    forall_index_equiv_list_for_all pred ls'
#pop-options

val find_update:
     #a:Type
  -> f:(a -> Tot bool)
  -> ls:list a
  -> x:a
  -> ls':list a{length ls' == length ls}
#push-options "--fuel 1"
let rec find_update #a f ls x =
  match ls with
  | [] -> []
  | hd::tl ->
    if f hd then x :: tl else hd :: find_update f tl x
#pop-options

val pairwise_distinct : #a:eqtype -> ls:list a -> Tot bool
let rec pairwise_distinct (#a : eqtype) (ls : list a) : Tot bool =
  match ls with
  | [] -> true
  | x :: ls' -> List.Tot.for_all (fun y -> x <> y) ls' && pairwise_distinct ls'

val pairwise_rel : #a:Type -> pred:(a -> a -> Tot bool) -> ls:list a -> Tot bool
let rec pairwise_rel #a pred ls =
  match ls with
  | [] -> true
  | x :: ls' ->
    for_all (pred x) ls' && pairwise_rel pred ls' 

#push-options "--fuel 1"
let rec flatten_append (#a : Type) (l1 l2: list (list a)) :
  Lemma (flatten (l1 @ l2) == flatten l1 @ flatten l2) =
  match l1 with
  | [] -> ()
  | x :: l1' ->
    flatten_append l1' l2;
    append_assoc x (flatten l1') (flatten l2)
#pop-options

/// We don't use anonymous functions as parameters to other functions, but rather
/// introduce auxiliary functions instead: otherwise we can't reason (because
/// F*'s encoding to the SMT is imprecise for functions)
let fst_is_disctinct (#a : eqtype) (#b : Type0) (p0 : a & b) (p1 : a & b) : Type0 =
  fst p0 <> fst p1

(*** Lemmas about Primitives *)
/// TODO: move those lemmas

// TODO: rename to 'insert'?
val list_update_index_dif_lem
  (#a : Type0) (ls : list a) (i : nat{i < length ls}) (x : a)
  (j : nat{j < length ls}) :
  Lemma (requires (j <> i))
  (ensures (index (list_update ls i x) j == index ls j))
  [SMTPat (index (list_update ls i x) j)]

#push-options "--fuel 1"
let rec list_update_index_dif_lem #a ls i x j =
  match ls with
  | x' :: ls ->
    if i = 0 then ()
    else if j = 0 then ()
    else
     list_update_index_dif_lem ls (i-1) x (j-1)
#pop-options

val map_list_update_lem
  (#a #b: Type0) (f : a -> Tot b)
  (ls : list a) (i : nat{i < length ls}) (x : a) :
  Lemma (list_update (map f ls) i (f x) == map f (list_update ls i x))
  [SMTPat (list_update (map f ls) i (f x))]

#push-options "--fuel 1"
let rec map_list_update_lem #a #b f ls i x =
  match ls with
  | x' :: ls' ->
    if i = 0 then ()
    else map_list_update_lem f ls' (i-1) x
#pop-options

(*** Invariants, models *)

(**** Internals *)
/// The following invariants, models, representation functions... are mostly
/// for the purpose of the proofs.

let is_pos_usize (n : nat) : Type0 = 0 < n /\ n <= usize_max
type pos_usize = x:usize{x > 0}

type binding (t : Type0) = key & t

type slots_t (t : Type0) = alloc_vec_Vec (list_t t)

/// We represent hash maps as associative lists
type assoc_list (t : Type0) = list (binding t)

/// Representation function for [list_t]
let rec list_t_v (#t : Type0) (ls : list_t t) : assoc_list t =
  match ls with
  | List_Nil -> []
  | List_Cons k v tl -> (k,v) :: list_t_v tl

let list_t_len (#t : Type0) (ls : list_t t) : nat = length (list_t_v ls)
let list_t_index (#t : Type0) (ls : list_t t) (i : nat{i < list_t_len ls}) : binding t =
  index (list_t_v ls) i

type slot_s (t : Type0) = list (binding t)
type slots_s (t : Type0) = list (slot_s t)

type slot_t (t : Type0) = list_t t
let slot_t_v #t = list_t_v #t

/// Representation function for the slots.
let slots_t_v (#t : Type0) (slots : slots_t t) : slots_s t =
  map slot_t_v slots

/// Representation function for the slots, seen as an associative list.
let slots_t_al_v (#t : Type0) (slots : slots_t t) : assoc_list t =
  flatten (map list_t_v slots)

/// High-level type for the hash-map, seen as a list of associative lists (one
/// list per slot). This is the representation we use most, internally. Note that
/// we later introduce a [map_s] representation, which is the one used in the
/// lemmas shown to the user.
type hashMap_s t = list (slot_s t)

// TODO: why not always have the condition on the length?
// 'nes': "non-empty slots"
type hashMap_s_nes (t : Type0) : Type0 =
  hm:hashMap_s t{is_pos_usize (length hm)}

/// Representation function for [hashMap_t] as a list of slots
let hashMap_t_v (#t : Type0) (hm : hashMap_t t) : hashMap_s t =
  map list_t_v hm.slots

/// Representation function for [hashMap_t] as an associative list
let hashMap_t_al_v (#t : Type0) (hm : hashMap_t t) : assoc_list t =
  flatten (hashMap_t_v hm)

// 'nes': "non-empty slots"
type hashMap_t_nes (t : Type0) : Type0 =
  hm:hashMap_t t{is_pos_usize (length hm.slots)}

let hash_key_s (k : key) : hash =
  Return?.v (hash_key k)

let hash_mod_key (k : key) (len : usize{len > 0}) : hash =
  (hash_key_s k) % len

let not_same_key (#t : Type0) (k : key) (b : binding t) : bool = fst b <> k
let same_key (#t : Type0) (k : key) (b : binding t) : bool = fst b = k

// We take a [nat] instead of a [hash] on purpose
let same_hash_mod_key (#t : Type0) (len : usize{len > 0}) (h : nat) (b : binding t) : bool =
  hash_mod_key (fst b) len = h

let binding_neq (#t : Type0) (b0 b1 : binding t) : bool = fst b0 <> fst b1

let hashMap_t_len_s (#t : Type0) (hm : hashMap_t t) : nat =
  hm.num_entries

let assoc_list_find (#t : Type0) (k : key) (slot : assoc_list t) : option t =
  match find (same_key k) slot with
  | None -> None
  | Some (_, v) -> Some v

let slot_s_find (#t : Type0) (k : key) (slot : list (binding t)) : option t =
  assoc_list_find k slot

let slot_t_find_s (#t : Type0) (k : key) (slot : list_t t) : option t =
  slot_s_find k (slot_t_v slot)

// This is a simpler version of the "find" function, which captures the essence
// of what happens and operates on [hashMap_s].
let hashMap_s_find
  (#t : Type0) (hm : hashMap_s_nes t)
  (k : key) : option t =
  let i = hash_mod_key k (length hm) in
  let slot = index hm i in
  slot_s_find k slot

let hashMap_s_len
  (#t : Type0) (hm : hashMap_s t) :
  nat =
  length (flatten hm)

// Same as above, but operates on [hashMap_t]
// Note that we don't reuse the above function on purpose: converting to a
// [hashMap_s] then looking up an element is not the same as what we
// wrote below.
let hashMap_t_find_s
  (#t : Type0) (hm : hashMap_t t{length hm.slots > 0}) (k : key) : option t =
  let slots = hm.slots in
  let i = hash_mod_key k (length slots) in
  let slot = index slots i in
  slot_t_find_s k slot

/// Invariants for the slots

let slot_s_inv
  (#t : Type0) (len : usize{len > 0}) (i : usize) (slot : list (binding t)) : bool =
  // All the bindings are in the proper slot
  for_all (same_hash_mod_key len i) slot &&
  // All the keys are pairwise distinct
  pairwise_rel binding_neq slot

let slot_t_inv (#t : Type0) (len : usize{len > 0}) (i : usize) (slot : list_t t) : bool =
  slot_s_inv len i (slot_t_v slot)

let slots_s_inv (#t : Type0) (slots : slots_s t{length slots <= usize_max}) : Type0 =
  forall(i:nat{i < length slots}).
  {:pattern index slots i}
  slot_s_inv (length slots) i (index slots i)

// At some point we tried to rewrite this in terms of [slots_s_inv]. However it
// made a lot of proofs fail because those proofs relied on the [index_map_lem]
// pattern. We tried writing others lemmas with patterns (like [slots_s_inv]
// implies [slots_t_inv]) but it didn't succeed, so we keep things as they are.
let slots_t_inv (#t : Type0) (slots : slots_t t{length slots <= usize_max}) : Type0 =
  forall(i:nat{i < length slots}).
  {:pattern index slots i}
  slot_t_inv (length slots) i (index slots i)

let hashMap_s_inv (#t : Type0) (hm : hashMap_s t) : Type0 =
  length hm <= usize_max /\
  length hm > 0 /\
  slots_s_inv hm

/// Base invariant for the hashmap (the complete invariant can be temporarily
/// broken between the moment we inserted an element and the moment we resize)
let hashMap_t_base_inv (#t : Type0) (hm : hashMap_t t) : Type0 =
  let al = hashMap_t_al_v hm in
  // [num_entries] correctly tracks the number of entries in the table
  // Note that it gives us that the length of the slots array is <= usize_max:
  // [> length <= usize_max
  // (because hashMap_num_entries has type `usize`)
  hm.num_entries = length al /\
  // Slots invariant
  slots_t_inv hm.slots /\
  // The capacity must be > 0 (otherwise we can't resize, because we
  // multiply the capacity by two!)
  length hm.slots > 0 /\
  // Load computation
  begin
  let capacity = length hm.slots in
  let (dividend, divisor) = hm.max_load_factor in
  0 < dividend /\ dividend < divisor /\
  capacity * dividend >= divisor /\
  hm.max_load = (capacity * dividend) / divisor
  end

/// We often need to frame some values
let hashMap_t_same_params (#t : Type0) (hm0 hm1 : hashMap_t t) : Type0 =
  length hm0.slots = length hm1.slots /\
  hm0.max_load = hm1.max_load /\
  hm0.max_load_factor = hm1.max_load_factor

/// The following invariants, etc. are meant to be revealed to the user through
/// the .fsti.

/// Invariant for the hashmap
let hashMap_t_inv (#t : Type0) (hm : hashMap_t t) : Type0 =
  // Base invariant
  hashMap_t_base_inv hm /\
  // The hash map is either: not overloaded, or we can't resize it
  begin
  let (dividend, divisor) = hm.max_load_factor in
  hm.num_entries <= hm.max_load
  || length hm.slots * 2 * dividend > usize_max
  end

(*** .fsti *)
/// We reveal slightly different version of the above functions to the user

let len_s (#t : Type0) (hm : hashMap_t t) : nat = hashMap_t_len_s hm

/// This version doesn't take any precondition (contrary to [hashMap_t_find_s])
let find_s (#t : Type0) (hm : hashMap_t t) (k : key) : option t =
  if length hm.slots = 0 then None
  else hashMap_t_find_s hm k

(*** Overloading *)

let hashMap_not_overloaded_lem #t hm = ()

(*** allocate_slots *)

/// Auxiliary lemma
val slots_t_all_nil_inv_lem
  (#t : Type0) (slots : alloc_vec_Vec (list_t t){length slots <= usize_max}) :
  Lemma (requires (forall (i:nat{i < length slots}). index slots i == List_Nil))
  (ensures (slots_t_inv slots))

#push-options "--fuel 1"
let slots_t_all_nil_inv_lem #t slots = ()
#pop-options

val slots_t_al_v_all_nil_is_empty_lem
  (#t : Type0) (slots : alloc_vec_Vec (list_t t)) :
  Lemma (requires (forall (i:nat{i < length slots}). index slots i == List_Nil))
  (ensures (slots_t_al_v slots == []))

#push-options "--fuel 1"
let rec slots_t_al_v_all_nil_is_empty_lem #t slots =
 match slots with
 | [] -> ()
 | s :: slots' ->
   assert(forall (i:nat{i < length slots'}). index slots' i == index slots (i+1));
   slots_t_al_v_all_nil_is_empty_lem #t slots';
   assert(slots_t_al_v slots == list_t_v s @ slots_t_al_v slots');
   assert(slots_t_al_v slots == list_t_v s);
   assert(index slots 0 == List_Nil)
#pop-options

/// [allocate_slots]
val hashMap_allocate_slots_lem
  (t : Type0) (slots : alloc_vec_Vec (list_t t)) (n : usize) :
  Lemma
  (requires (length slots + n <= usize_max))
  (ensures (
   match hashMap_allocate_slots t slots n with
   | Fail _ -> False
   | Return slots' ->
     length slots' = length slots + n /\
     // We leave the already allocated slots unchanged
     (forall (i:nat{i < length slots}). index slots' i == index slots i) /\
     // We allocate n additional empty slots
     (forall (i:nat{length slots <= i /\ i < length slots'}). index slots' i == List_Nil)))
  (decreases (hashMap_allocate_slots_loop_decreases t slots n))

#push-options "--fuel 1"
let rec hashMap_allocate_slots_lem t slots n =
  begin match n with
  | 0 -> ()
  | _ ->
    begin match alloc_vec_Vec_push (list_t t) slots List_Nil with
    | Fail _ -> ()
    | Return slots1 ->
      begin match usize_sub n 1 with
      | Fail _ -> ()
      | Return i ->
        hashMap_allocate_slots_lem t slots1 i;
        begin match hashMap_allocate_slots t slots1 i with
        | Fail _ -> ()
        | Return slots2 ->
          assert(length slots1 = length slots + 1);
          assert(slots1 == slots @ [List_Nil]); // Triggers patterns
          assert(index slots1 (length slots) == index [List_Nil] 0); // Triggers patterns
          assert(index slots1 (length slots) == List_Nil)
        end
      end
    end
  end
#pop-options

(*** new_with_capacity *)
/// Under proper conditions, [new_with_capacity] doesn't fail and returns an empty hash map.
val hashMap_new_with_capacity_lem
  (t : Type0) (capacity : usize)
  (max_load_dividend : usize) (max_load_divisor : usize) :
  Lemma
  (requires (
    0 < max_load_dividend /\
    max_load_dividend < max_load_divisor /\
    0 < capacity /\
    capacity * max_load_dividend >= max_load_divisor /\
    capacity * max_load_dividend <= usize_max))
  (ensures (
    match hashMap_new_with_capacity t capacity max_load_dividend max_load_divisor with
    | Fail _ -> False
    | Return hm ->
      // The hash map invariant is satisfied
      hashMap_t_inv hm /\
      // The parameters are correct
      hm.max_load_factor = (max_load_dividend, max_load_divisor) /\
      hm.max_load = (capacity * max_load_dividend) / max_load_divisor /\
      // The hash map has the specified capacity - we need to reveal this
      // otherwise the pre of [hashMap_t_find_s] is not satisfied.
      length hm.slots = capacity /\
      // The hash map has 0 values
      hashMap_t_len_s hm = 0 /\
      // It contains no bindings
      (forall k. hashMap_t_find_s hm k == None) /\
      // We need this low-level property for the invariant
      (forall(i:nat{i < length hm.slots}). index hm.slots i == List_Nil)))

#push-options "--z3rlimit 50 --fuel 1"
let hashMap_new_with_capacity_lem (t : Type0) (capacity : usize)
  (max_load_dividend : usize) (max_load_divisor : usize) =
  let v = alloc_vec_Vec_new (list_t t) in
  assert(length v = 0);
  hashMap_allocate_slots_lem t v capacity;
  begin match hashMap_allocate_slots t v capacity with
  | Fail _ -> assert(False)
  | Return v0 ->
    begin match usize_mul capacity max_load_dividend with
    | Fail _ -> assert(False)
    | Return i ->
      begin match usize_div i max_load_divisor with
      | Fail _ -> assert(False)
      | Return i0 ->
          let hm = MkhashMap_t 0 (max_load_dividend, max_load_divisor) i0 v0 in
          slots_t_all_nil_inv_lem v0;
          slots_t_al_v_all_nil_is_empty_lem hm.slots
      end
    end
  end
#pop-options

(*** new *)

/// [new] doesn't fail and returns an empty hash map
val hashMap_new_lem_aux (t : Type0) :
  Lemma
  (ensures (
    match hashMap_new t with
    | Fail _ -> False
    | Return hm ->
      // The hash map invariant is satisfied
      hashMap_t_inv hm /\
      // The hash map has 0 values
      hashMap_t_len_s hm = 0 /\
      // It contains no bindings
      (forall k. hashMap_t_find_s hm k == None)))

#push-options "--fuel 1"
let hashMap_new_lem_aux t =
  hashMap_new_with_capacity_lem t 32 4 5;
  match hashMap_new_with_capacity t 32 4 5 with
  | Fail _ -> ()
  | Return hm -> ()
#pop-options

/// The lemma we reveal in the .fsti
let hashMap_new_lem t = hashMap_new_lem_aux t

(*** clear *)
/// [clear]: the loop doesn't fail and simply clears the slots starting at index i
#push-options "--fuel 1"
let rec hashMap_clear_loop_lem
  (t : Type0) (slots : alloc_vec_Vec (list_t t)) (i : usize) :
  Lemma
  (ensures (
    match hashMap_clear_loop t slots i with
    | Fail _ -> False
    | Return slots' ->
      // The length is preserved
      length slots' == length slots /\
      // The slots before i are left unchanged
      (forall (j:nat{j < i /\ j < length slots}). index slots' j == index slots j) /\
      // The slots after i are set to List_Nil
      (forall (j:nat{i <= j /\ j < length slots}). index slots' j == List_Nil)))
  (decreases (hashMap_clear_loop_decreases t slots i))
  =
  let i0 = alloc_vec_Vec_len (list_t t) slots in
  let b = i < i0 in
  if b
  then
    begin match alloc_vec_Vec_update_usize slots i List_Nil with
    | Fail _ -> ()
    | Return v ->
      begin match usize_add i 1 with
      | Fail _ -> ()
      | Return i1 ->
        hashMap_clear_loop_lem t v i1;
        begin match hashMap_clear_loop t v i1 with
        | Fail _ -> ()
        | Return slots1 ->
          assert(length slots1 == length slots);
          assert(forall (j:nat{i+1 <= j /\ j < length slots}). index slots1 j == List_Nil);
          assert(index slots1 i == List_Nil)
        end
      end
    end
  else ()
#pop-options

/// [clear] doesn't fail and turns the hash map into an empty map
val hashMap_clear_lem_aux
  (#t : Type0) (self : hashMap_t t) :
  Lemma
  (requires (hashMap_t_base_inv self))
  (ensures (
    match hashMap_clear t self with
    | Fail _ -> False
    | Return hm ->
      // The hash map invariant is satisfied
      hashMap_t_base_inv hm /\
      // We preserved the parameters
      hashMap_t_same_params hm self /\
      // The hash map has 0 values
      hashMap_t_len_s hm = 0 /\
      // It contains no bindings
      (forall k. hashMap_t_find_s hm k == None)))

// Being lazy: fuel 1 helps a lot...
#push-options "--fuel 1"
let hashMap_clear_lem_aux #t self =
  let p = self.max_load_factor in
  let i = self.max_load in
  let v = self.slots in
  hashMap_clear_loop_lem t v 0;
  begin match hashMap_clear_loop t v 0 with
  | Fail _ -> ()
  | Return slots1 ->
    slots_t_al_v_all_nil_is_empty_lem slots1;
    let hm1 = MkhashMap_t 0 p i slots1 in
    assert(hashMap_t_base_inv hm1);
    assert(hashMap_t_inv hm1)
  end
#pop-options

let hashMap_clear_lem #t self = hashMap_clear_lem_aux #t self

(*** len *)

/// [len]: we link it to a non-failing function.
/// Rk.: we might want to make an analysis to not use an error monad to translate
/// functions which statically can't fail.
let hashMap_len_lem #t self = ()


(*** insert_in_list *)

(**** insert_in_list'fwd *)

/// [insert_in_list]: returns true iff the key is not in the list (functional version)
val hashMap_insert_in_list_lem
  (t : Type0) (key : usize) (value : t) (ls : list_t t) :
  Lemma
  (ensures (
    match hashMap_insert_in_list t key value ls with
    | Fail _ -> False
    | Return b ->
      b <==> (slot_t_find_s key ls == None)))
  (decreases (hashMap_insert_in_list_loop_decreases t key value ls))

#push-options "--fuel 1"
let rec hashMap_insert_in_list_lem t key value ls =
  begin match ls with
  | List_Cons ckey cvalue ls0 ->
    let b = ckey = key in
    if b
    then ()
    else
      begin
      hashMap_insert_in_list_lem t key value ls0;
      match hashMap_insert_in_list t key value ls0 with
      | Fail _ -> ()
      | Return b0 -> ()
      end
  | List_Nil ->
    assert(list_t_v ls == []);
    assert_norm(find (same_key #t key) [] == None)
  end
#pop-options

(**** insert_in_list'back *)

/// The proofs about [insert_in_list] backward are easier to do in several steps:
/// extrinsic proofs to the rescue!
/// We first prove that [insert_in_list] refines the function we wrote above, then
/// use this function to prove the invariants, etc.

/// We write a helper which "captures" what [insert_in_list] does.
/// We then reason about this helper to prove the high-level properties we want
/// (functional properties, preservation of invariants, etc.).
let hashMap_insert_in_list_s
  (#t : Type0) (key : usize) (value : t) (ls : list (binding t)) :
  list (binding t) =
  // Check if there is already a binding for the key
  match find (same_key key) ls with
  | None ->
    // No binding: append the binding to the end
    ls @ [(key,value)]
  | Some _ ->
    // There is already a binding: update it
    find_update (same_key key) ls (key,value)

/// [insert_in_list]: if the key is not in the map, appends a new bindings (functional version)
val hashMap_insert_in_list_back_lem_append_s
  (t : Type0) (key : usize) (value : t) (ls : list_t t) :
  Lemma
  (requires (
    slot_t_find_s key ls == None))
  (ensures (
    match hashMap_insert_in_list_back t key value ls with
    | Fail _ -> False
    | Return ls' ->
      list_t_v ls' == list_t_v ls @ [(key,value)]))
  (decreases (hashMap_insert_in_list_loop_decreases t key value ls))

#push-options "--fuel 1"
let rec hashMap_insert_in_list_back_lem_append_s t key value ls =
  begin match ls with
  | List_Cons ckey cvalue ls0 ->
    let b = ckey = key in
    if b
    then ()
    else
      begin
      hashMap_insert_in_list_back_lem_append_s t key value ls0;
      match hashMap_insert_in_list_back t key value ls0 with
      | Fail _ -> ()
      | Return l -> ()
      end
  | List_Nil -> ()
  end
#pop-options

/// [insert_in_list]: if the key is in the map, we update the binding (functional version)
val hashMap_insert_in_list_back_lem_update_s
  (t : Type0) (key : usize) (value : t) (ls : list_t t) :
  Lemma
  (requires (
    Some? (find (same_key key) (list_t_v ls))))
  (ensures (
    match hashMap_insert_in_list_back t key value ls with
    | Fail _ -> False
    | Return ls' ->
      list_t_v ls' == find_update (same_key key) (list_t_v ls) (key,value)))
  (decreases (hashMap_insert_in_list_loop_decreases t key value ls))

#push-options "--fuel 1"
let rec hashMap_insert_in_list_back_lem_update_s t key value ls =
  begin match ls with
  | List_Cons ckey cvalue ls0 ->
    let b = ckey = key in
    if b
    then ()
    else
      begin
      hashMap_insert_in_list_back_lem_update_s t key value ls0;
      match hashMap_insert_in_list_back t key value ls0 with
      | Fail _ -> ()
      | Return l -> ()
      end
  | List_Nil -> ()
  end
#pop-options

/// Put everything together
val hashMap_insert_in_list_back_lem_s
  (t : Type0) (key : usize) (value : t) (ls : list_t t) :
  Lemma
  (ensures (
    match hashMap_insert_in_list_back t key value ls with
    | Fail _ -> False
    | Return ls' ->
      list_t_v ls' == hashMap_insert_in_list_s key value (list_t_v ls)))

let hashMap_insert_in_list_back_lem_s t key value ls =
  match find (same_key key) (list_t_v ls) with
  | None -> hashMap_insert_in_list_back_lem_append_s t key value ls
  | Some _ -> hashMap_insert_in_list_back_lem_update_s t key value ls

(**** Invariants of insert_in_list_s *)

/// Auxiliary lemmas
/// We work on [hashMap_insert_in_list_s], the "high-level" version of [insert_in_list'back].
///
/// Note that in F* we can't have recursive proofs inside of other proofs, contrary
/// to Coq, which makes it a bit cumbersome to prove auxiliary results like the
/// following ones...

(** Auxiliary lemmas: append case *)

val slot_t_v_for_all_binding_neq_append_lem
  (t : Type0) (key : usize) (value : t) (ls : list (binding t)) (b : binding t) :
  Lemma
  (requires (
    fst b <> key /\
    for_all (binding_neq b) ls /\
    slot_s_find key ls == None))
  (ensures (
    for_all (binding_neq b) (ls @ [(key,value)])))

#push-options "--fuel 1"
let rec slot_t_v_for_all_binding_neq_append_lem t key value ls b =
  match ls with
  | [] -> ()
  | (ck, cv) :: cls ->
    slot_t_v_for_all_binding_neq_append_lem t key value cls b
#pop-options

val slot_s_inv_not_find_append_end_inv_lem
  (t : Type0) (len : usize{len > 0}) (key : usize) (value : t) (ls : list (binding t)) :
  Lemma
  (requires (
    slot_s_inv len (hash_mod_key key len) ls /\
    slot_s_find key ls == None))
  (ensures (
    let ls' = ls @ [(key,value)] in
    slot_s_inv len (hash_mod_key key len) ls' /\
    (slot_s_find key ls' == Some value) /\
    (forall k'. k' <> key ==> slot_s_find k' ls' == slot_s_find k' ls)))

#push-options "--fuel 1"
let rec slot_s_inv_not_find_append_end_inv_lem t len key value ls =
  match ls with
  | [] -> ()
  | (ck, cv) :: cls ->
    slot_s_inv_not_find_append_end_inv_lem t len key value cls;
    let h = hash_mod_key key len in
    let ls' = ls @ [(key,value)] in
    assert(for_all (same_hash_mod_key len h) ls');
    slot_t_v_for_all_binding_neq_append_lem t key value cls (ck, cv);
    assert(pairwise_rel binding_neq ls');
    assert(slot_s_inv len h ls')
#pop-options

/// [insert_in_list]: if the key is not in the map, appends a new bindings
val hashMap_insert_in_list_s_lem_append
  (t : Type0) (len : usize{len > 0}) (key : usize) (value : t) (ls : list (binding t)) :
  Lemma
  (requires (
    slot_s_inv len (hash_mod_key key len) ls /\
    slot_s_find key ls == None))
  (ensures (
    let ls' = hashMap_insert_in_list_s key value ls in
    ls' == ls @ [(key,value)] /\
    // The invariant is preserved
    slot_s_inv len (hash_mod_key key len) ls' /\
    // [key] maps to [value]
    slot_s_find key ls' == Some value /\
    // The other bindings are preserved
    (forall k'. k' <> key ==> slot_s_find k' ls' == slot_s_find k' ls)))

let hashMap_insert_in_list_s_lem_append t len key value ls =
  slot_s_inv_not_find_append_end_inv_lem t len key value ls

/// [insert_in_list]: if the key is not in the map, appends a new bindings (quantifiers)
/// Rk.: we don't use this lemma.
/// TODO: remove?
val hashMap_insert_in_list_back_lem_append
  (t : Type0) (len : usize{len > 0}) (key : usize) (value : t) (ls : list_t t) :
  Lemma
  (requires (
    slot_t_inv len (hash_mod_key key len) ls /\
    slot_t_find_s key ls == None))
  (ensures (
    match hashMap_insert_in_list_back t key value ls with
    | Fail _ -> False
    | Return ls' ->
      list_t_v ls' == list_t_v ls @ [(key,value)] /\
      // The invariant is preserved
      slot_t_inv len (hash_mod_key key len) ls' /\
      // [key] maps to [value]
      slot_t_find_s key ls' == Some value /\
      // The other bindings are preserved
      (forall k'. k' <> key ==> slot_t_find_s k' ls' == slot_t_find_s k' ls)))

let hashMap_insert_in_list_back_lem_append t len key value ls =
  hashMap_insert_in_list_back_lem_s t key value ls;
  hashMap_insert_in_list_s_lem_append t len key value (list_t_v ls)

(** Auxiliary lemmas: update case *)

val slot_s_find_update_for_all_binding_neq_append_lem
  (t : Type0) (key : usize) (value : t) (ls : list (binding t)) (b : binding t) :
  Lemma
  (requires (
    fst b <> key /\
    for_all (binding_neq b) ls))
  (ensures (
    let ls' = find_update (same_key key) ls (key, value) in
    for_all (binding_neq b) ls'))

#push-options "--fuel 1"
let rec slot_s_find_update_for_all_binding_neq_append_lem t key value ls b =
  match ls with
  | [] -> ()
  | (ck, cv) :: cls ->
    slot_s_find_update_for_all_binding_neq_append_lem t key value cls b
#pop-options

/// Annoying auxiliary lemma we have to prove because there is no way to reason
/// properly about closures.
/// I'm really enjoying my time.
val for_all_binding_neq_value_indep
  (#t : Type0) (key : key) (v0 v1 : t) (ls : list (binding t)) :
  Lemma (for_all (binding_neq (key,v0)) ls = for_all (binding_neq (key,v1)) ls)

#push-options "--fuel 1"
let rec for_all_binding_neq_value_indep #t key v0 v1 ls =
  match ls with
  | [] -> ()
  | _ :: ls' -> for_all_binding_neq_value_indep #t key v0 v1 ls'
#pop-options

val slot_s_inv_find_append_end_inv_lem
  (t : Type0) (len : usize{len > 0}) (key : usize) (value : t) (ls : list (binding t)) :
  Lemma
  (requires (
    slot_s_inv len (hash_mod_key key len) ls /\
    Some? (slot_s_find key ls)))
  (ensures (
    let ls' = find_update (same_key key) ls (key, value) in
    slot_s_inv len (hash_mod_key key len) ls' /\
    (slot_s_find key ls' == Some value) /\
    (forall k'. k' <> key ==> slot_s_find k' ls' == slot_s_find k' ls)))

#push-options "--z3rlimit 50 --fuel 1"
let rec slot_s_inv_find_append_end_inv_lem t len key value ls =
  match ls with
  | [] -> ()
  | (ck, cv) :: cls ->
    let h = hash_mod_key key len in
    let ls' = find_update (same_key key) ls (key, value) in
    if ck = key then
      begin
      assert(ls' == (ck,value) :: cls);
      assert(for_all (same_hash_mod_key len h) ls');
      // For pairwise_rel: binding_neq (ck, value) is actually independent
      // of `value`. Slightly annoying to prove in F*...
      assert(for_all (binding_neq (ck,cv)) cls);
      for_all_binding_neq_value_indep key cv value cls;
      assert(for_all (binding_neq (ck,value)) cls);
      assert(pairwise_rel binding_neq ls');
      assert(slot_s_inv len (hash_mod_key key len) ls')
      end
    else
      begin
      slot_s_inv_find_append_end_inv_lem t len key value cls;
      assert(for_all (same_hash_mod_key len h) ls');
      slot_s_find_update_for_all_binding_neq_append_lem t key value cls (ck, cv);
      assert(pairwise_rel binding_neq ls');
      assert(slot_s_inv len h ls')
      end
#pop-options

/// [insert_in_list]: if the key is in the map, update the bindings
val hashMap_insert_in_list_s_lem_update
  (t : Type0) (len : usize{len > 0}) (key : usize) (value : t) (ls : list (binding t)) :
  Lemma
  (requires (
    slot_s_inv len (hash_mod_key key len) ls /\
    Some? (slot_s_find key ls)))
  (ensures (
    let ls' = hashMap_insert_in_list_s key value ls in
    ls' == find_update (same_key key) ls (key,value) /\
    // The invariant is preserved
    slot_s_inv len (hash_mod_key key len) ls' /\
    // [key] maps to [value]
    slot_s_find key ls' == Some value /\
    // The other bindings are preserved
    (forall k'. k' <> key ==> slot_s_find k' ls' == slot_s_find k' ls)))

let hashMap_insert_in_list_s_lem_update t len key value ls =
  slot_s_inv_find_append_end_inv_lem t len key value ls


/// [insert_in_list]: if the key is in the map, update the bindings
/// TODO: not used: remove?
val hashMap_insert_in_list_back_lem_update
  (t : Type0) (len : usize{len > 0}) (key : usize) (value : t) (ls : list_t t) :
  Lemma
  (requires (
    slot_t_inv len (hash_mod_key key len) ls /\
    Some? (slot_t_find_s key ls)))
  (ensures (
    match hashMap_insert_in_list_back t key value ls with
    | Fail _ -> False
    | Return ls' ->
      let als = list_t_v ls in
      list_t_v ls' == find_update (same_key key) als (key,value) /\
      // The invariant is preserved
      slot_t_inv len (hash_mod_key key len) ls' /\
      // [key] maps to [value]
      slot_t_find_s key ls' == Some value /\
      // The other bindings are preserved
      (forall k'. k' <> key ==> slot_t_find_s k' ls' == slot_t_find_s k' ls)))

let hashMap_insert_in_list_back_lem_update t len key value ls =
  hashMap_insert_in_list_back_lem_s t key value ls;
  hashMap_insert_in_list_s_lem_update t len key value (list_t_v ls)

(** Final lemmas about [insert_in_list] *)

/// High-level version
val hashMap_insert_in_list_s_lem
  (t : Type0) (len : usize{len > 0}) (key : usize) (value : t) (ls : list (binding t)) :
  Lemma
  (requires (
    slot_s_inv len (hash_mod_key key len) ls))
  (ensures (
    let ls' = hashMap_insert_in_list_s key value ls in
    // The invariant is preserved
    slot_s_inv len (hash_mod_key key len) ls' /\
    // [key] maps to [value]
    slot_s_find key ls' == Some value /\
    // The other bindings are preserved
    (forall k'. k' <> key ==> slot_s_find k' ls' == slot_s_find k' ls) /\
    // The length is incremented, iff we inserted a new key
    (match slot_s_find key ls with
     | None -> length ls' = length ls + 1
     | Some _ -> length ls' = length ls)))

let hashMap_insert_in_list_s_lem t len key value ls =
  match slot_s_find key ls with
  | None ->
    assert_norm(length [(key,value)] = 1);
    hashMap_insert_in_list_s_lem_append t len key value ls
  | Some _ ->
    hashMap_insert_in_list_s_lem_update t len key value ls

/// [insert_in_list]
/// TODO: not used: remove?
val hashMap_insert_in_list_back_lem
  (t : Type0) (len : usize{len > 0}) (key : usize) (value : t) (ls : list_t t) :
  Lemma
  (requires (slot_t_inv len (hash_mod_key key len) ls))
  (ensures (
    match hashMap_insert_in_list_back t key value ls with
    | Fail _ -> False
    | Return ls' ->
      // The invariant is preserved
      slot_t_inv len (hash_mod_key key len) ls' /\
      // [key] maps to [value]
      slot_t_find_s key ls' == Some value /\
      // The other bindings are preserved
      (forall k'. k' <> key ==> slot_t_find_s k' ls' == slot_t_find_s k' ls) /\
      // The length is incremented, iff we inserted a new key
      (match slot_t_find_s key ls with
       | None ->
         list_t_v ls' == list_t_v ls @ [(key,value)] /\
         list_t_len ls' = list_t_len ls + 1
       | Some _ ->
         list_t_v ls' == find_update (same_key key) (list_t_v ls) (key,value) /\
         list_t_len ls' = list_t_len ls)))
  (decreases (hashMap_insert_in_list_loop_decreases t key value ls))

let hashMap_insert_in_list_back_lem t len key value ls =
  hashMap_insert_in_list_back_lem_s t key value ls;
  hashMap_insert_in_list_s_lem t len key value (list_t_v ls)

(*** insert_no_resize *)

(**** Refinement proof *)
/// Same strategy as for [insert_in_list]: we introduce a high-level version of
/// the function, and reason about it.
/// We work on [hashMap_s] (we use a higher-level view of the hash-map, but
/// not too high).

/// A high-level version of insert, which doesn't check if the table is saturated
let hashMap_insert_no_fail_s
  (#t : Type0) (hm : hashMap_s_nes t)
  (key : usize) (value : t) :
  hashMap_s t =
  let len = length hm in
  let i = hash_mod_key key len in
  let slot = index hm i in
  let slot' = hashMap_insert_in_list_s key value slot in
  let hm' = list_update hm i slot' in
  hm'

// TODO: at some point I used hashMap_s_nes and it broke proofs...x
let hashMap_insert_no_resize_s
  (#t : Type0) (hm : hashMap_s_nes t)
  (key : usize) (value : t) :
  result (hashMap_s t) =
  // Check if the table is saturated (too many entries, and we need to insert one)
  let num_entries = length (flatten hm) in
  if None? (hashMap_s_find hm key) && num_entries = usize_max then Fail Failure
  else Return (hashMap_insert_no_fail_s hm key value)

/// Prove that [hashMap_insert_no_resize_s] is refined by
/// [hashMap_insert_no_resize'fwd_back]
val hashMap_insert_no_resize_lem_s
  (t : Type0) (self : hashMap_t t) (key : usize) (value : t) :
  Lemma
  (requires (
    hashMap_t_base_inv self /\
    hashMap_s_len (hashMap_t_v self) = hashMap_t_len_s self))
  (ensures (
    begin
    match hashMap_insert_no_resize t self key value,
          hashMap_insert_no_resize_s (hashMap_t_v self) key value
    with
    | Fail _, Fail _ -> True
    | Return hm, Return hm_v ->
      hashMap_t_base_inv hm /\
      hashMap_t_same_params hm self /\
      hashMap_t_v hm == hm_v /\
      hashMap_s_len hm_v == hashMap_t_len_s hm
    | _ -> False
    end))

let hashMap_insert_no_resize_lem_s t self key value =
  begin match hash_key key with
  | Fail _ -> ()
  | Return i ->
    let i0 = self.num_entries in
    let p = self.max_load_factor in
    let i1 = self.max_load in
    let v = self.slots in
    let i2 = alloc_vec_Vec_len (list_t t) v in
    let len = length v in
    begin match usize_rem i i2 with
    | Fail _ -> ()
    | Return hash_mod ->
      begin match alloc_vec_Vec_index_usize v hash_mod with
      | Fail _ -> ()
      | Return l ->
        begin
        // Checking that: list_t_v (index ...) == index (hashMap_t_v ...) ...
        assert(list_t_v l == index (hashMap_t_v self) hash_mod);
        hashMap_insert_in_list_lem t key value l;
        match hashMap_insert_in_list t key value l with
        | Fail _ -> ()
        | Return b ->
          assert(b = None? (slot_s_find key (list_t_v l)));
          hashMap_insert_in_list_back_lem t len key value l;
          if b
          then
            begin match usize_add i0 1 with
            | Fail _ -> ()
            | Return i3 ->
              begin
              match hashMap_insert_in_list_back t key value l with
              | Fail _ -> ()
              | Return l0 ->
                begin match alloc_vec_Vec_update_usize v hash_mod l0 with
                | Fail _ -> ()
                | Return v0 ->
                  let self_v = hashMap_t_v self in
                  let hm = MkhashMap_t i3 p i1 v0 in
                  let hm_v = hashMap_t_v hm in
                  assert(hm_v == list_update self_v hash_mod (list_t_v l0));
                  assert_norm(length [(key,value)] = 1);
                  assert(length (list_t_v l0) = length (list_t_v l) + 1);
                  length_flatten_update self_v hash_mod (list_t_v l0);
                  assert(hashMap_s_len hm_v = hashMap_t_len_s hm)
                end
              end
            end
          else
            begin
            match hashMap_insert_in_list_back t key value l with
            | Fail _ -> ()
            | Return l0 ->
              begin match alloc_vec_Vec_update_usize v hash_mod l0 with
              | Fail _ -> ()
              | Return v0 ->
                let self_v = hashMap_t_v self in
                let hm = MkhashMap_t i0 p i1 v0 in
                let hm_v = hashMap_t_v hm in
                assert(hm_v == list_update self_v hash_mod (list_t_v l0));
                assert(length (list_t_v l0) = length (list_t_v l));
                length_flatten_update self_v hash_mod (list_t_v l0);
                assert(hashMap_s_len hm_v = hashMap_t_len_s hm)
              end
            end
        end
      end
    end
  end

(**** insert_{no_fail,no_resize}: invariants *)

let hashMap_s_updated_binding
  (#t : Type0) (hm : hashMap_s_nes t)
  (key : usize) (opt_value : option t) (hm' : hashMap_s_nes t) : Type0 =
  // [key] maps to [value]
  hashMap_s_find hm' key == opt_value /\
  // The other bindings are preserved
  (forall k'. k' <> key ==> hashMap_s_find hm' k' == hashMap_s_find hm k')

let insert_post (#t : Type0) (hm : hashMap_s_nes t)
  (key : usize) (value : t) (hm' : hashMap_s_nes t) : Type0 =
  // The invariant is preserved
  hashMap_s_inv hm' /\
  // [key] maps to [value] and the other bindings are preserved
  hashMap_s_updated_binding hm key (Some value) hm' /\
  // The length is incremented, iff we inserted a new key
  (match hashMap_s_find hm key with
   | None -> hashMap_s_len hm' = hashMap_s_len hm + 1
   | Some _ -> hashMap_s_len hm' = hashMap_s_len hm)

val hashMap_insert_no_fail_s_lem
  (#t : Type0) (hm : hashMap_s_nes t)
  (key : usize) (value : t) :
  Lemma
  (requires (hashMap_s_inv hm))
  (ensures (
    let hm' = hashMap_insert_no_fail_s hm key value in
    insert_post hm key value hm'))

let hashMap_insert_no_fail_s_lem #t hm key value =
  let len = length hm in
  let i = hash_mod_key key len in
  let slot = index hm i in
  hashMap_insert_in_list_s_lem t len key value slot;
  let slot' = hashMap_insert_in_list_s key value slot in
  length_flatten_update hm i slot'

val hashMap_insert_no_resize_s_lem
  (#t : Type0) (hm : hashMap_s_nes t)
  (key : usize) (value : t) :
  Lemma
  (requires (hashMap_s_inv hm))
  (ensures (
    match hashMap_insert_no_resize_s hm key value with
    | Fail _ ->
      // Can fail only if we need to create a new binding in
      // an already saturated map
      hashMap_s_len hm = usize_max /\
      None? (hashMap_s_find hm key)
    | Return hm' ->
      insert_post hm key value hm'))

let hashMap_insert_no_resize_s_lem #t hm key value =
  let num_entries = length (flatten hm) in
  if None? (hashMap_s_find hm key) && num_entries = usize_max then ()
  else hashMap_insert_no_fail_s_lem hm key value


(**** find after insert *)
/// Lemmas about what happens if we call [find] after an insertion

val hashMap_insert_no_resize_s_get_same_lem
  (#t : Type0) (hm : hashMap_s t)
  (key : usize) (value : t) :
  Lemma (requires (hashMap_s_inv hm))
  (ensures (
    match hashMap_insert_no_resize_s hm key value with
    | Fail _ -> True
    | Return hm' ->
      hashMap_s_find hm' key == Some value))

let hashMap_insert_no_resize_s_get_same_lem #t hm key value =
  let num_entries = length (flatten hm) in
  if None? (hashMap_s_find hm key) && num_entries = usize_max then ()
  else
    begin
    let hm' = Return?.v (hashMap_insert_no_resize_s hm key value) in
    let len = length hm in
    let i = hash_mod_key key len in
    let slot = index hm i in
    hashMap_insert_in_list_s_lem t len key value slot
   end

val hashMap_insert_no_resize_s_get_diff_lem
  (#t : Type0) (hm : hashMap_s t)
  (key : usize) (value : t) (key' : usize{key' <> key}) :
  Lemma (requires (hashMap_s_inv hm))
  (ensures (
    match hashMap_insert_no_resize_s hm key value with
    | Fail _ -> True
    | Return hm' ->
      hashMap_s_find hm' key' == hashMap_s_find hm key'))

let hashMap_insert_no_resize_s_get_diff_lem #t hm key value key' =
  let num_entries = length (flatten hm) in
  if None? (hashMap_s_find hm key) && num_entries = usize_max then ()
  else
    begin
    let hm' = Return?.v (hashMap_insert_no_resize_s hm key value) in
    let len = length hm in
    let i = hash_mod_key key len in
    let slot = index hm i in
    hashMap_insert_in_list_s_lem t len key value slot;
    let i' = hash_mod_key key' len in
    if i <> i' then ()
    else
      begin
      ()
      end
   end


(*** move_elements_from_list *)

/// Having a great time here: if we use `result (hashMap_s_res t)` as the
/// return type for [hashMap_move_elements_from_list_s] instead of having this
/// awkward match, the proof of [hashMap_move_elements_lem_refin] fails.
/// I guess it comes from F*'s poor subtyping.
/// Followingly, I'm not taking any chance and using [result_hashMap_s]
/// everywhere.
type result_hashMap_s_nes (t : Type0) : Type0 =
  res:result (hashMap_s t) {
    match res with
    | Fail _ -> True
    | Return hm -> is_pos_usize (length hm)
  }

let rec hashMap_move_elements_from_list_s
  (#t : Type0) (hm : hashMap_s_nes t)
  (ls : slot_s t) :
  // Do *NOT* use `result (hashMap_s t)`
  Tot (result_hashMap_s_nes t)
  (decreases ls) =
  match ls with
  | [] -> Return hm
  | (key, value) :: ls' ->
    match hashMap_insert_no_resize_s hm key value with
    | Fail e -> Fail e
    | Return hm' ->
      hashMap_move_elements_from_list_s hm' ls'

/// Refinement lemma
val hashMap_move_elements_from_list_lem
  (t : Type0) (ntable : hashMap_t_nes t) (ls : list_t t) :
  Lemma (requires (hashMap_t_base_inv ntable))
  (ensures (
    match hashMap_move_elements_from_list t ntable ls,
          hashMap_move_elements_from_list_s (hashMap_t_v ntable) (slot_t_v ls)
    with
    | Fail _, Fail _ -> True
    | Return hm', Return hm_v ->
      hashMap_t_base_inv hm' /\
      hashMap_t_v hm' == hm_v /\
      hashMap_t_same_params hm' ntable
    | _ -> False))
  (decreases (hashMap_move_elements_from_list_loop_decreases t ntable ls))

#push-options "--fuel 1"
let rec hashMap_move_elements_from_list_lem t ntable ls =
  begin match ls with
  | List_Cons k v tl ->
    assert(list_t_v ls == (k, v) :: list_t_v tl);
    let ls_v = list_t_v ls in
    let (_,_) :: tl_v = ls_v in
    hashMap_insert_no_resize_lem_s t ntable k v;
    begin match hashMap_insert_no_resize t ntable k v with
    | Fail _ -> ()
    | Return h ->
      let h_v = Return?.v (hashMap_insert_no_resize_s (hashMap_t_v ntable) k v) in
      assert(hashMap_t_v h == h_v);
      hashMap_move_elements_from_list_lem t h tl;
      begin match hashMap_move_elements_from_list t h tl with
      | Fail _ -> ()
      | Return h0 -> ()
      end
    end
  | List_Nil -> ()
  end
#pop-options

(*** move_elements *)

(**** move_elements: refinement 0 *)
/// The proof for [hashMap_move_elements_lem_refin] broke so many times
/// (while it is supposed to be super simple!) that we decided to add one refinement
/// level, to really do things step by step...
/// Doing this refinement layer made me notice that maybe the problem came from
/// the fact that at some point we have to prove `list_t_v List_Nil == []`: I
/// added the corresponding assert to help Z3 and everything became stable.
/// I finally didn't use this "simple" refinement lemma, but I still keep it here
/// because it allows for easy comparisons with [hashMap_move_elements_s].

/// [hashMap_move_elements] refines this function, which is actually almost
/// the same (just a little bit shorter and cleaner, and has a pre).
///
/// The way I wrote the high-level model is the following:
/// - I copy-pasted the definition of [hashMap_move_elements], wrote the
///   signature which links this new definition to [hashMap_move_elements] and
///   checked that the proof passed
/// - I gradually simplified it, while making sure the proof still passes
#push-options "--fuel 1"
let rec hashMap_move_elements_s_simpl
  (t : Type0) (ntable : hashMap_t t)
  (slots : alloc_vec_Vec (list_t t))
  (i : usize{i <= length slots /\ length slots <= usize_max}) :
  Pure (result ((hashMap_t t) & (alloc_vec_Vec (list_t t))))
  (requires (True))
  (ensures (fun res ->
    match res, hashMap_move_elements t ntable slots i with
    | Fail _, Fail _ -> True
    | Return (ntable1, slots1), Return (ntable2, slots2) ->
      ntable1 == ntable2 /\
      slots1 == slots2
    | _ -> False))
  (decreases (hashMap_move_elements_loop_decreases t ntable slots i))
  =
  if i < length slots
  then
    let slot = index slots i in
    begin match hashMap_move_elements_from_list t ntable slot with
    | Fail e -> Fail e
    | Return hm' ->
      let slots' = list_update slots i List_Nil in
      hashMap_move_elements_s_simpl t hm' slots' (i+1)
    end
  else Return (ntable, slots)
#pop-options

(**** move_elements: refinement 1 *)
/// We prove a second refinement lemma: calling [move_elements] refines a function
/// which, for every slot, moves the element out of the slot. This first model is
/// almost exactly the translated function, it just uses `list` instead of `list_t`.

// Note that we ignore the returned slots (we thus don't return a pair:
// only the new hash map in which we moved the elements from the slots):
// this returned value is not used.
let rec hashMap_move_elements_s
  (#t : Type0) (hm : hashMap_s_nes t)
  (slots : slots_s t) (i : usize{i <= length slots /\ length slots <= usize_max}) :
  Tot (result_hashMap_s_nes t)
  (decreases (length slots - i)) =
  let len = length slots in
  if i < len then
    begin
    let slot = index slots i in
    match hashMap_move_elements_from_list_s hm slot with
    | Fail e -> Fail e
    | Return hm' ->
      let slots' = list_update slots i [] in
      hashMap_move_elements_s hm' slots' (i+1)
    end
  else Return hm

val hashMap_move_elements_lem_refin
  (t : Type0) (ntable : hashMap_t t)
  (slots : alloc_vec_Vec (list_t t)) (i : usize{i <= length slots}) :
  Lemma
  (requires (
    hashMap_t_base_inv ntable))
  (ensures (
    match hashMap_move_elements t ntable slots i,
          hashMap_move_elements_s (hashMap_t_v ntable) (slots_t_v slots) i
    with
    | Fail _, Fail _ -> True // We will prove later that this is not possible
    | Return (ntable', _), Return ntable'_v ->
      hashMap_t_base_inv ntable' /\
      hashMap_t_v ntable' == ntable'_v /\
      hashMap_t_same_params ntable' ntable
    | _ -> False))
 (decreases (length slots - i))

#restart-solver
#push-options "--fuel 1"
let rec hashMap_move_elements_lem_refin t ntable slots i =
  assert(hashMap_t_base_inv ntable);
  let i0 = alloc_vec_Vec_len (list_t t) slots in
  let b = i < i0 in
  if b
  then
    begin match alloc_vec_Vec_index_usize slots i with
    | Fail _ -> ()
    | Return l ->
      let l0 = core_mem_replace (list_t t) l List_Nil in
      assert(l0 == l);
      hashMap_move_elements_from_list_lem t ntable l0;
      begin match hashMap_move_elements_from_list t ntable l0 with
      | Fail _ -> ()
      | Return h ->
        let l1 = core_mem_replace_back (list_t t) l List_Nil in
        assert(l1 == List_Nil);
        assert(slot_t_v #t List_Nil == []); // THIS IS IMPORTANT
        begin match alloc_vec_Vec_update_usize slots i l1 with
        | Fail _ -> ()
        | Return v ->
          begin match usize_add i 1 with
          | Fail _ -> ()
          | Return i1 ->
            hashMap_move_elements_lem_refin t h v i1;
            begin match hashMap_move_elements t h v i1 with
            | Fail _ ->
              assert(Fail? (hashMap_move_elements t ntable slots i));
              ()
            | Return (ntable', v0) -> ()
            end
          end
        end
      end
    end
  else ()
#pop-options


(**** move_elements: refinement 2 *)
/// We prove a second refinement lemma: calling [move_elements] refines a function
/// which moves every binding of the hash map seen as *one* associative list
/// (and not a list of lists).

/// [ntable] is the hash map to which we move the elements
/// [slots] is the current hash map, from which we remove the elements, and seen
///         as a "flat" associative list (and not a list of lists)
/// This is actually exactly [hashMap_move_elements_from_list_s]...
let rec hashMap_move_elements_s_flat
  (#t : Type0) (ntable : hashMap_s_nes t)
  (slots : assoc_list t) :
  Tot (result_hashMap_s_nes t)
  (decreases slots) =
  match slots with
  | [] -> Return ntable
  | (k,v) :: slots' ->
    match hashMap_insert_no_resize_s ntable k v with
    | Fail e -> Fail e
    | Return ntable' ->
      hashMap_move_elements_s_flat ntable' slots'

/// The refinment lemmas
/// First, auxiliary helpers.

/// Flatten a list of lists, starting at index i
val flatten_i :
     #a:Type
  -> l:list (list a)
  -> i:nat{i <= length l}
  -> Tot (list a) (decreases (length l - i))

let rec flatten_i l i =
  if i < length l then
    index l i @ flatten_i l (i+1)
  else []

let _ = assert(let l = [1;2] in l == hd l :: tl l)

val flatten_i_incr :
     #a:Type
  -> l:list (list a)
  -> i:nat{Cons? l /\ i+1 <= length l} ->
  Lemma
  (ensures (
    (**) assert_norm(length (hd l :: tl l) == 1 + length (tl l));
    flatten_i l (i+1) == flatten_i (tl l) i))
  (decreases (length l - (i+1)))

#push-options "--fuel 1"
let rec flatten_i_incr l i =
  let x :: tl = l in
  if i + 1 < length l then
    begin
    assert(flatten_i l (i+1) == index l (i+1) @ flatten_i l (i+2));
    flatten_i_incr l (i+1);
    assert(flatten_i l (i+2) == flatten_i tl (i+1));
    assert(index l (i+1) == index tl i)
    end
  else ()
#pop-options

val flatten_0_is_flatten :
     #a:Type
  -> l:list (list a) ->
  Lemma
  (ensures (flatten_i l 0 == flatten l))

#push-options "--fuel 1"
let rec flatten_0_is_flatten #a l =
  match l with
  | [] -> ()
  | x :: l' ->
    flatten_i_incr l 0;
    flatten_0_is_flatten l'
#pop-options

/// Auxiliary lemma
val flatten_nil_prefix_as_flatten_i :
     #a:Type
  -> l:list (list a)
  -> i:nat{i <= length l} ->
  Lemma (requires (forall (j:nat{j < i}). index l j == []))
  (ensures (flatten l == flatten_i l i))

#push-options "--fuel 1"
let rec flatten_nil_prefix_as_flatten_i #a l i =
  if i = 0 then flatten_0_is_flatten l
  else
    begin
    let x :: l' = l in
    assert(index l 0 == []);
    assert(x == []);
    assert(flatten l == flatten l');
    flatten_i_incr l (i-1);
    assert(flatten_i l i == flatten_i l' (i-1));
    assert(forall (j:nat{j < length l'}). index l' j == index l (j+1));
    flatten_nil_prefix_as_flatten_i l' (i-1);
    assert(flatten l' == flatten_i l' (i-1))
    end
#pop-options

/// The proof is trivial, the functions are the same.
/// Just keeping two definitions to allow changes...
val hashMap_move_elements_from_list_s_as_flat_lem
  (#t : Type0) (hm : hashMap_s_nes t)
  (ls : slot_s t) :
  Lemma
  (ensures (
    hashMap_move_elements_from_list_s hm ls ==
    hashMap_move_elements_s_flat hm ls))
  (decreases ls)

#push-options "--fuel 1"
let rec hashMap_move_elements_from_list_s_as_flat_lem #t hm ls =
  match ls with
  | [] -> ()
  | (key, value) :: ls' ->
    match hashMap_insert_no_resize_s hm key value with
    | Fail _ -> ()
    | Return hm' ->
      hashMap_move_elements_from_list_s_as_flat_lem hm' ls'
#pop-options

/// Composition of two calls to [hashMap_move_elements_s_flat]
let hashMap_move_elements_s_flat_comp
  (#t : Type0) (hm : hashMap_s_nes t) (slot0 slot1 : slot_s t) :
  Tot (result_hashMap_s_nes t) =
  match hashMap_move_elements_s_flat hm slot0 with
  | Fail e -> Fail e
  | Return hm1 -> hashMap_move_elements_s_flat hm1 slot1

/// High-level desc:
/// move_elements (move_elements hm slot0) slo1 == move_elements hm (slot0 @ slot1)
val hashMap_move_elements_s_flat_append_lem
  (#t : Type0) (hm : hashMap_s_nes t) (slot0 slot1 : slot_s t) :
  Lemma
  (ensures (
    match hashMap_move_elements_s_flat_comp hm slot0 slot1,
          hashMap_move_elements_s_flat hm (slot0 @ slot1)
    with
    | Fail _, Fail _ -> True
    | Return hm1, Return hm2 -> hm1 == hm2
    | _ -> False))
  (decreases (slot0))

#push-options "--fuel 1"
let rec hashMap_move_elements_s_flat_append_lem #t hm slot0 slot1 =
  match slot0 with
  | [] -> ()
  | (k,v) :: slot0' ->
    match hashMap_insert_no_resize_s hm k v with
    | Fail _ -> ()
    | Return hm' ->
      hashMap_move_elements_s_flat_append_lem hm' slot0' slot1
#pop-options

val flatten_i_same_suffix (#a : Type) (l0 l1 : list (list a)) (i : nat) :
  Lemma
  (requires (
    i <= length l0 /\
    length l0 = length l1 /\
    (forall (j:nat{i <= j /\ j < length l0}). index l0 j == index l1 j)))
  (ensures (flatten_i l0 i == flatten_i l1 i))
  (decreases (length l0 - i))

#push-options "--fuel 1"
let rec flatten_i_same_suffix #a l0 l1 i =
  if i < length l0 then
    flatten_i_same_suffix l0 l1 (i+1)
  else ()
#pop-options

/// Refinement lemma:
/// [hashMap_move_elements_s] refines [hashMap_move_elements_s_flat]
/// (actually the functions are equal on all inputs).
val hashMap_move_elements_s_lem_refin_flat
  (#t : Type0) (hm : hashMap_s_nes t)
  (slots : slots_s t)
  (i : nat{i <= length slots /\ length slots <= usize_max}) :
  Lemma
  (ensures (
    match hashMap_move_elements_s hm slots i,
          hashMap_move_elements_s_flat hm (flatten_i slots i)
    with
    | Fail _, Fail _ -> True
    | Return hm, Return hm' -> hm == hm'
    | _ -> False))
  (decreases (length slots - i))

#push-options "--fuel 1"
let rec hashMap_move_elements_s_lem_refin_flat #t hm slots i =
  let len = length slots in
  if i < len then
    begin
    let slot = index slots i in
    hashMap_move_elements_from_list_s_as_flat_lem hm slot;
    match hashMap_move_elements_from_list_s hm slot with
    | Fail _ ->
      assert(flatten_i slots i == slot @ flatten_i slots (i+1));
      hashMap_move_elements_s_flat_append_lem hm slot (flatten_i slots (i+1));
      assert(Fail? (hashMap_move_elements_s_flat hm (flatten_i slots i)))
    | Return hm' ->
      let slots' = list_update slots i [] in
      flatten_i_same_suffix slots slots' (i+1);
      hashMap_move_elements_s_lem_refin_flat hm' slots' (i+1);
      hashMap_move_elements_s_flat_append_lem hm slot (flatten_i slots' (i+1));
      ()
    end
  else ()
#pop-options

let assoc_list_inv (#t : Type0) (al : assoc_list t) : Type0 =
  // All the keys are pairwise distinct
  pairwise_rel binding_neq al

let disjoint_hm_al_on_key
  (#t : Type0) (hm : hashMap_s_nes t) (al : assoc_list t) (k : key) : Type0 =
  match hashMap_s_find hm k, assoc_list_find k al with
  | Some _, None
  | None, Some _
  | None, None -> True
  | Some _, Some _ -> False

/// Playing a dangerous game here: using forall quantifiers
let disjoint_hm_al (#t : Type0) (hm : hashMap_s_nes t) (al : assoc_list t) : Type0 =
  forall (k:key). disjoint_hm_al_on_key hm al k

let find_in_union_hm_al
  (#t : Type0) (hm : hashMap_s_nes t) (al : assoc_list t) (k : key) :
  option t =
  match hashMap_s_find hm k with
  | Some b -> Some b
  | None -> assoc_list_find k al

/// Auxiliary lemma
val for_all_binding_neq_find_lem (#t : Type0) (k : key) (v : t) (al : assoc_list t) :
  Lemma (requires (for_all (binding_neq (k,v)) al))
  (ensures (assoc_list_find k al == None))

#push-options "--fuel 1"
let rec for_all_binding_neq_find_lem #t k v al =
  match al with
  | [] -> ()
  | b :: al' -> for_all_binding_neq_find_lem k v al'
#pop-options

val hashMap_move_elements_s_flat_lem
  (#t : Type0) (hm : hashMap_s_nes t) (al : assoc_list t) :
  Lemma
  (requires (
    // Invariants
    hashMap_s_inv hm /\
    assoc_list_inv al /\
    // The two are disjoint
    disjoint_hm_al hm al /\
    // We can add all the elements to the hashmap
    hashMap_s_len hm + length al <= usize_max))
  (ensures (
    match hashMap_move_elements_s_flat hm al with
    | Fail _ -> False // We can't fail
    | Return hm' ->
      // The invariant is preserved
      hashMap_s_inv hm' /\
      // The new hash map is the union of the two maps
      (forall (k:key). hashMap_s_find hm' k == find_in_union_hm_al hm al k) /\
      hashMap_s_len hm' = hashMap_s_len hm + length al))
  (decreases al)

#restart-solver
#push-options "--z3rlimit 200 --fuel 1"
let rec hashMap_move_elements_s_flat_lem #t hm al =
  match al with
  | [] -> ()
  | (k,v) :: al' ->
    hashMap_insert_no_resize_s_lem hm k v;
    match hashMap_insert_no_resize_s hm k v with
    | Fail _ -> ()
    | Return hm' ->
      assert(hashMap_s_inv hm');
      assert(assoc_list_inv al');
      let disjoint_lem (k' : key) :
        Lemma (disjoint_hm_al_on_key hm' al' k')
        [SMTPat (disjoint_hm_al_on_key hm' al' k')] =
        if k' = k then
          begin
          assert(hashMap_s_find hm' k' == Some v);
          for_all_binding_neq_find_lem k v al';
          assert(assoc_list_find k' al' == None)
          end
        else
          begin
          assert(hashMap_s_find hm' k' == hashMap_s_find hm k');
          assert(assoc_list_find k' al' == assoc_list_find k' al)
          end
      in
      assert(disjoint_hm_al hm' al');
      assert(hashMap_s_len hm' + length al' <= usize_max);
      hashMap_move_elements_s_flat_lem hm' al'
#pop-options

/// We need to prove that the invariants on the "low-level" representations of
/// the hash map imply the invariants on the "high-level" representations.

val slots_t_inv_implies_slots_s_inv
  (#t : Type0) (slots : slots_t t{length slots <= usize_max}) :
  Lemma (requires (slots_t_inv slots))
  (ensures (slots_s_inv (slots_t_v slots)))

let slots_t_inv_implies_slots_s_inv #t slots =
  // Ok, works fine: this lemma was useless.
  // Problem is: I can never really predict for sure with F*...
  ()

val hashMap_t_base_inv_implies_hashMap_s_inv
  (#t : Type0) (hm : hashMap_t t) :
  Lemma (requires (hashMap_t_base_inv hm))
  (ensures (hashMap_s_inv (hashMap_t_v hm)))

let hashMap_t_base_inv_implies_hashMap_s_inv #t hm = () // same as previous

/// Introducing a "partial" version of the hash map invariant, which operates on
/// a suffix of the hash map.
let partial_hashMap_s_inv
  (#t : Type0) (len : usize{len > 0}) (offset : usize)
  (hm : hashMap_s t{offset + length hm <= usize_max}) : Type0 =
  forall(i:nat{i < length hm}). {:pattern index hm i} slot_s_inv len (offset + i) (index hm i)

/// Auxiliary lemma.
/// If a binding comes from a slot i, then its key is different from the keys
/// of the bindings in the other slots (because the hashes of the keys are distinct).
val binding_in_previous_slot_implies_neq
  (#t : Type0) (len : usize{len > 0})
  (i : usize) (b : binding t)
  (offset : usize{i < offset})
  (slots : hashMap_s t{offset + length slots <= usize_max}) :
  Lemma
  (requires (
    // The binding comes from a slot not in [slots]
    hash_mod_key (fst b) len = i /\
    // The slots are the well-formed suffix of a hash map
    partial_hashMap_s_inv len offset slots))
  (ensures (
    for_all (binding_neq b) (flatten slots)))
  (decreases slots)

#push-options "--z3rlimit 100 --fuel 1"
let rec binding_in_previous_slot_implies_neq #t len i b offset slots =
  match slots with
  | [] -> ()
  | s :: slots' ->
    assert(slot_s_inv len offset (index slots 0)); // Triggers patterns
    assert(slot_s_inv len offset s);
    // Proving TARGET. We use quantifiers.
    assert(for_all (same_hash_mod_key len offset) s);
    forall_index_equiv_list_for_all (same_hash_mod_key len offset) s;
    assert(forall (i:nat{i < length s}). same_hash_mod_key len offset (index s i));
    let aux (i:nat{i < length s}) :
      Lemma
      (requires (same_hash_mod_key len offset (index s i)))
      (ensures (binding_neq b (index s i)))
      [SMTPat (index s i)] = ()
    in
    assert(forall (i:nat{i < length s}). binding_neq b (index s i));
    forall_index_equiv_list_for_all (binding_neq b) s;
    assert(for_all (binding_neq b) s); // TARGET
    //
    assert(forall (i:nat{i < length slots'}). index slots' i == index slots (i+1)); // Triggers instantiations
    binding_in_previous_slot_implies_neq len i b (offset+1) slots';
    for_all_append (binding_neq b) s (flatten slots')    
#pop-options

val partial_hashMap_s_inv_implies_assoc_list_lem
  (#t : Type0) (len : usize{len > 0}) (offset : usize)
  (hm : hashMap_s t{offset + length hm <= usize_max}) :
  Lemma
  (requires (
    partial_hashMap_s_inv len offset hm))
  (ensures (assoc_list_inv (flatten hm)))
  (decreases (length hm + length (flatten hm)))

#push-options "--fuel 1"
let rec partial_hashMap_s_inv_implies_assoc_list_lem #t len offset hm =
  match hm with
  | [] -> ()
  | slot :: hm' ->
    assert(flatten hm == slot @ flatten hm');
    assert(forall (i:nat{i < length hm'}). index hm' i == index hm (i+1)); // Triggers instantiations
    match slot with
    | [] ->
      assert(flatten hm == flatten hm');
      assert(partial_hashMap_s_inv len (offset+1) hm'); // Triggers instantiations
      partial_hashMap_s_inv_implies_assoc_list_lem len (offset+1) hm'
    | x :: slot' ->
      assert(flatten (slot' :: hm') == slot' @ flatten hm');
      let hm'' = slot' :: hm' in
      assert(forall (i:nat{0 < i /\ i < length hm''}). index hm'' i == index hm i); // Triggers instantiations
      assert(forall (i:nat{0 < i /\ i < length hm''}). slot_s_inv len (offset + i) (index hm'' i));
      assert(index hm 0 == slot); // Triggers instantiations
      assert(slot_s_inv len offset slot);
      assert(slot_s_inv len offset slot');
      assert(partial_hashMap_s_inv len offset hm'');
      partial_hashMap_s_inv_implies_assoc_list_lem len offset (slot' :: hm');
      // Proving that the key in `x` is different from all the other keys in
      // the flattened map
      assert(for_all (binding_neq x) slot');
      for_all_append (binding_neq x) slot' (flatten hm');
      assert(partial_hashMap_s_inv len (offset+1) hm');
      binding_in_previous_slot_implies_neq #t len offset x (offset+1) hm';
      assert(for_all (binding_neq x) (flatten hm'));
      assert(for_all (binding_neq x) (flatten (slot' :: hm')))
#pop-options

val hashMap_s_inv_implies_assoc_list_lem
  (#t : Type0) (hm : hashMap_s t) :
  Lemma (requires (hashMap_s_inv hm))
  (ensures (assoc_list_inv (flatten hm)))

let hashMap_s_inv_implies_assoc_list_lem #t hm =
  partial_hashMap_s_inv_implies_assoc_list_lem (length hm) 0 hm

val hashMap_t_base_inv_implies_assoc_list_lem
  (#t : Type0) (hm : hashMap_t t):
  Lemma (requires (hashMap_t_base_inv hm))
  (ensures (assoc_list_inv (hashMap_t_al_v hm)))

let hashMap_t_base_inv_implies_assoc_list_lem #t hm =
  hashMap_s_inv_implies_assoc_list_lem (hashMap_t_v hm)

/// For some reason, we can't write the below [forall] directly in the [ensures]
/// clause of the next lemma: it makes Z3 fails even with a huge rlimit.
/// I have no idea what's going on.
let hashMap_is_assoc_list
  (#t : Type0) (ntable : hashMap_t t{length ntable.slots > 0})
  (al : assoc_list t) : Type0 =
  (forall (k:key). hashMap_t_find_s ntable k == assoc_list_find k al)

let partial_hashMap_s_find
  (#t : Type0) (len : usize{len > 0}) (offset : usize)
  (hm : hashMap_s_nes t{offset + length hm = len})
  (k : key{hash_mod_key k len >= offset}) : option t =
  let i = hash_mod_key k len in
  let slot = index hm (i - offset) in
  slot_s_find k slot

val not_same_hash_key_not_found_in_slot
  (#t : Type0) (len : usize{len > 0})
  (k : key)
  (i : usize)
  (slot : slot_s t) :
  Lemma
  (requires (
    hash_mod_key k len <> i /\
    slot_s_inv len i slot))
  (ensures (slot_s_find k slot == None))

#push-options "--fuel 1"
let rec not_same_hash_key_not_found_in_slot #t len k i slot =
  match slot with
  | [] -> ()
  | (k',v) :: slot' -> not_same_hash_key_not_found_in_slot len k i slot'
#pop-options

/// Small variation of [binding_in_previous_slot_implies_neq]: if the hash of
/// a key links it to a previous slot, it can't be found in the slots after.
val key_in_previous_slot_implies_not_found
  (#t : Type0) (len : usize{len > 0})
  (k : key)
  (offset : usize)
  (slots : hashMap_s t{offset + length slots = len}) :
  Lemma
  (requires (
    // The binding comes from a slot not in [slots]
    hash_mod_key k len < offset /\
    // The slots are the well-formed suffix of a hash map
    partial_hashMap_s_inv len offset slots))
  (ensures (
    assoc_list_find k (flatten slots) == None))
  (decreases slots)

#push-options "--fuel 1"
let rec key_in_previous_slot_implies_not_found #t len k offset slots =
  match slots with
  | [] -> ()
  | slot :: slots' ->
    find_append (same_key k) slot (flatten slots');
    assert(index slots 0 == slot); // Triggers instantiations
    not_same_hash_key_not_found_in_slot #t len k offset slot;
    assert(assoc_list_find k slot == None);
    assert(forall (i:nat{i < length slots'}). index slots' i == index slots (i+1)); // Triggers instantiations
    key_in_previous_slot_implies_not_found len k (offset+1) slots'
#pop-options  

val partial_hashMap_s_is_assoc_list_lem
  (#t : Type0) (len : usize{len > 0}) (offset : usize)
  (hm : hashMap_s_nes t{offset + length hm = len})
  (k : key{hash_mod_key k len >= offset}) :
  Lemma
  (requires (
    partial_hashMap_s_inv len offset hm))
  (ensures (
    partial_hashMap_s_find len offset hm k == assoc_list_find k (flatten hm)))
  (decreases hm)

#push-options "--fuel 1"
let rec partial_hashMap_s_is_assoc_list_lem #t len offset hm k =
  match hm with
  | [] -> ()
  | slot :: hm' ->
    let h = hash_mod_key k len in
    let i = h - offset in
    if i = 0 then
      begin
      // We must look in the current slot
      assert(partial_hashMap_s_find len offset hm k == slot_s_find k slot);
      find_append (same_key k) slot (flatten hm');
      assert(forall (i:nat{i < length hm'}). index hm' i == index hm (i+1)); // Triggers instantiations
      key_in_previous_slot_implies_not_found #t len k (offset+1) hm';
      assert( // Of course, writing `== None` doesn't work...
        match find (same_key k) (flatten hm') with
        | None -> True
        | Some _ -> False);
      assert(
        find (same_key k) (flatten hm) ==
        begin match find (same_key k) slot with
        | Some x -> Some x
        | None -> find (same_key k) (flatten hm')
        end);
      ()
      end
    else
      begin
      // We must ignore the current slot
      assert(partial_hashMap_s_find len offset hm k ==
             partial_hashMap_s_find len (offset+1) hm' k);
      find_append (same_key k) slot (flatten hm');
      assert(index hm 0 == slot); // Triggers instantiations
      not_same_hash_key_not_found_in_slot #t len k offset slot;
      assert(forall (i:nat{i < length hm'}). index hm' i == index hm (i+1)); // Triggers instantiations
      partial_hashMap_s_is_assoc_list_lem #t len (offset+1) hm' k
      end
#pop-options

val hashMap_is_assoc_list_lem (#t : Type0) (hm : hashMap_t t) :
  Lemma (requires (hashMap_t_base_inv hm))
  (ensures (hashMap_is_assoc_list hm (hashMap_t_al_v hm)))

let hashMap_is_assoc_list_lem #t hm =
  let aux (k:key) :
    Lemma (hashMap_t_find_s hm k == assoc_list_find k (hashMap_t_al_v hm))
    [SMTPat (hashMap_t_find_s hm k)] =
    let hm_v = hashMap_t_v hm in
    let len = length hm_v in
    partial_hashMap_s_is_assoc_list_lem #t len 0 hm_v k
  in
  ()

/// The final lemma about [move_elements]: calling it on an empty hash table moves
/// all the elements to this empty table.
val hashMap_move_elements_lem
  (t : Type0) (ntable : hashMap_t t) (slots : alloc_vec_Vec (list_t t)) :
  Lemma
  (requires (
    let al = flatten (slots_t_v slots) in
    hashMap_t_base_inv ntable /\
    length al <= usize_max /\
    assoc_list_inv al /\
    // The table is empty
    hashMap_t_len_s ntable = 0 /\
    (forall (k:key). hashMap_t_find_s ntable k  == None)))
  (ensures (
    let al = flatten (slots_t_v slots) in
    match hashMap_move_elements t ntable slots 0,
          hashMap_move_elements_s_flat (hashMap_t_v ntable) al
    with
    | Return (ntable', _), Return ntable'_v ->
      // The invariant is preserved
      hashMap_t_base_inv ntable' /\
      // We preserved the parameters
      hashMap_t_same_params ntable' ntable /\
      // The table has the same number of slots
      length ntable'.slots = length ntable.slots /\
      // The count is good
      hashMap_t_len_s ntable' = length al /\
      // The table can be linked to its model (we need this only to reveal
      // "pretty" functional lemmas to the user in the fsti - so that we
      // can write lemmas with SMT patterns - this is very F* specific)
      hashMap_t_v ntable' == ntable'_v /\
      // The new table contains exactly all the bindings from the slots
      // Rk.: see the comment for [hashMap_is_assoc_list]
      hashMap_is_assoc_list ntable' al
    | _ -> False // We can only succeed
    ))

// Weird, dirty things happen below.
// Manually unfolding some postconditions allowed to make the proof pass,
// and also revealed the reason why some proofs failed with "Unknown assertion
// failed" (resulting in the call to [flatten_0_is_flatten] for instance).
// I think manually unfolding the postconditions allowed to account for the
// lack of ifuel (this kind of proofs is annoying, really).
#restart-solver
#push-options "--z3rlimit 100"
let hashMap_move_elements_lem t ntable slots =
  let ntable_v = hashMap_t_v ntable in
  let slots_v = slots_t_v slots in
  let al = flatten slots_v in
  hashMap_move_elements_lem_refin t ntable slots 0;
  begin
  match hashMap_move_elements t ntable slots 0,
        hashMap_move_elements_s ntable_v slots_v 0
  with
  | Fail _, Fail _ -> ()
  | Return (ntable', _), Return ntable'_v ->
    assert(hashMap_t_base_inv ntable');
    assert(hashMap_t_v ntable' == ntable'_v)
  | _ -> assert(False)
  end;
  hashMap_move_elements_s_lem_refin_flat ntable_v slots_v 0;
  begin
  match hashMap_move_elements_s ntable_v slots_v 0,
        hashMap_move_elements_s_flat ntable_v (flatten_i slots_v 0)
  with
  | Fail _, Fail _ -> ()
  | Return hm, Return hm' -> assert(hm == hm')
  | _ -> assert(False)
  end;
  flatten_0_is_flatten slots_v; // flatten_i slots_v 0 == flatten slots_v
  hashMap_move_elements_s_flat_lem ntable_v al;
  match hashMap_move_elements t ntable slots 0,
        hashMap_move_elements_s_flat ntable_v al
  with
  | Return (ntable', _), Return ntable'_v ->
    assert(hashMap_t_base_inv ntable');
    assert(length ntable'.slots = length ntable.slots);
    assert(hashMap_t_len_s ntable' = length al);
    assert(hashMap_t_v ntable' == ntable'_v);
    assert(hashMap_is_assoc_list ntable' al)
  | _ -> assert(False)
#pop-options

(*** try_resize *)

/// High-level model 1.
/// This is one is slightly "crude": we just simplify a bit the function.

let hashMap_try_resize_s_simpl
  (#t : Type0)
  (hm : hashMap_t t) :
  Pure  (result (hashMap_t t))
  (requires (
    let (divid, divis) = hm.max_load_factor in
    divid > 0 /\ divis > 0))
  (ensures (fun _ -> True)) =
  let capacity = length hm.slots in
  let (divid, divis) = hm.max_load_factor in
  if capacity <= (usize_max / 2) / divid then
    let ncapacity : usize = capacity * 2 in
    begin match hashMap_new_with_capacity t ncapacity divid divis with
    | Fail e -> Fail e
    | Return ntable ->
      match hashMap_move_elements t ntable hm.slots 0 with
      | Fail e -> Fail e
      | Return (ntable', _) ->
        let hm =
          { hm with slots = ntable'.slots;
                    max_load = ntable'.max_load }
        in
        Return hm
    end
  else Return hm

val hashMap_try_resize_lem_refin
  (t : Type0) (self : hashMap_t t) :
  Lemma
  (requires (
    let (divid, divis) = self.max_load_factor in
    divid > 0 /\ divis > 0))
  (ensures (
    match hashMap_try_resize t self,
          hashMap_try_resize_s_simpl self
    with
    | Fail _, Fail _ -> True
    | Return hm1, Return hm2 -> hm1 == hm2
    | _ -> False))

let hashMap_try_resize_lem_refin t self = ()

/// Isolating arithmetic proofs

let gt_lem0 (n m q : nat) :
  Lemma (requires (m > 0 /\ n > q))
  (ensures (n * m > q * m)) = ()

let ge_lem0 (n m q : nat) :
  Lemma (requires (m > 0 /\ n >= q))
  (ensures (n * m >= q * m)) = ()

let gt_ge_trans (n m p : nat) :
  Lemma (requires (n > m /\ m >= p)) (ensures (n > p)) = ()

let ge_trans (n m p : nat) :
  Lemma (requires (n >= m /\ m >= p)) (ensures (n >= p)) = ()

#push-options "--z3rlimit 200"
let gt_lem1 (n m q : nat) :
  Lemma (requires (m > 0 /\ n > q / m)) (ensures (n * m > q)) =
  assert(n >= q / m + 1);
  ge_lem0 n m (q / m + 1);
  assert(n * m >= (q / m) * m + m)
#pop-options

let gt_lem2 (n m p q : nat) :
  Lemma (requires (m > 0 /\ p > 0 /\ n > (q / m) / p)) (ensures (n * m * p > q)) =
  gt_lem1 n p (q / m);
  assert(n * p > q / m);
  gt_lem1 (n * p) m q

let ge_lem1 (n m q : nat) :
  Lemma (requires (n >= m /\ q > 0))
  (ensures (n / q >= m / q)) =
  FStar.Math.Lemmas.lemma_div_le m n q

#restart-solver
#push-options "--z3rlimit 200"
let times_divid_lem (n m p : pos) : Lemma ((n * m) / p >= n * (m / p))
  =
  FStar.Math.Lemmas.multiply_fractions m p;
  assert(m >= (m / p) * p);
  assert(n * m >= n * (m / p) * p); //
  ge_lem1 (n * m) (n * (m / p) * p) p;
  assert((n * m) / p >= (n * (m / p) * p) / p);
  assert(n * (m / p) * p = (n * (m / p)) * p);
  FStar.Math.Lemmas.cancel_mul_div (n * (m / p)) p;
  assert(((n * (m / p)) * p) / p = n * (m / p))
#pop-options

/// The good old arithmetic proofs and their unstability...
/// At some point I thought it was stable because it worked with `--quake 100`.
/// Of course, it broke the next time I checked the file...
/// It seems things are ok when we check this proof on its own, but not when
/// it is sent at the same time as the one above (though we put #restart-solver!).
/// I also tried `--quake 1/100` to no avail: it seems that when Z3 decides to
/// fail the first one, it fails them all. I inserted #restart-solver before
/// the previous lemma to see if it had an effect (of course not).
val new_max_load_lem
  (len : usize) (capacity : usize{capacity > 0})
  (divid : usize{divid > 0}) (divis : usize{divis > 0}) :
  Lemma
  (requires (
    let max_load = (capacity * divid) / divis in
    let ncapacity = 2 * capacity in
    let nmax_load = (ncapacity * divid) / divis in
    capacity > 0 /\ 0 < divid /\ divid < divis /\
    capacity * divid >= divis /\
    len = max_load + 1))
  (ensures (
    let max_load = (capacity * divid) / divis in
    let ncapacity = 2 * capacity in
    let nmax_load = (ncapacity * divid) / divis in
    len <= nmax_load))

let mul_assoc (a b c : nat) : Lemma (a * b * c == a * (b * c)) = ()

let ge_lem2 (a b c d : nat) : Lemma (requires (a >= b + c /\ c >= d)) (ensures (a >= b + d)) = ()
let ge_div_lem1 (a b : nat) : Lemma (requires (a >= b /\ b > 0)) (ensures (a / b >= 1)) = ()

#restart-solver
#push-options "--z3rlimit 100 --z3cliopt smt.arith.nl=false"
let new_max_load_lem len capacity divid divis =
  FStar.Math.Lemmas.paren_mul_left 2 capacity divid;
  mul_assoc 2 capacity divid;
  // The following assertion often breaks though it is given by the above
  // lemma. I really don't know what to do (I deactivated non-linear
  // arithmetic and added the previous lemma call, moved the assertion up,
  // boosted the rlimit...).
  assert(2 * capacity * divid == 2 * (capacity * divid));
  let max_load = (capacity * divid) / divis in
  let ncapacity = 2 * capacity in
  let nmax_load = (ncapacity * divid) / divis in
  assert(nmax_load = (2 * capacity * divid) / divis);
  times_divid_lem 2 (capacity * divid) divis;
  assert((2 * (capacity * divid)) / divis >= 2 * ((capacity * divid) / divis));
  assert(nmax_load >= 2 * ((capacity * divid) / divis));
  assert(nmax_load >= 2 * max_load);
  assert(nmax_load >= max_load + max_load);
  ge_div_lem1 (capacity * divid) divis;
  ge_lem2 nmax_load max_load max_load 1;
  assert(nmax_load >= max_load + 1)
#pop-options

val hashMap_try_resize_s_simpl_lem (#t : Type0) (hm : hashMap_t t) :
  Lemma
  (requires (
    // The base invariant is satisfied
    hashMap_t_base_inv hm /\
    // However, the "full" invariant is broken, as we call [try_resize]
    // only if the current number of entries is > the max load.
    // 
    // There are two situations:
    // - either we just reached the max load
    // - or we were already saturated and can't resize
    (let (dividend, divisor) = hm.max_load_factor in
     hm.num_entries == hm.max_load + 1 \/
     length hm.slots * 2 * dividend > usize_max)
  ))
  (ensures (
    match hashMap_try_resize_s_simpl hm with
    | Fail _ -> False
    | Return hm' ->
      // The full invariant is now satisfied (the full invariant is "base
      // invariant" + the map is not overloaded (or can't be resized because
      // already too big)
      hashMap_t_inv hm' /\
      // It contains the same bindings as the initial map
      (forall (k:key). hashMap_t_find_s hm' k == hashMap_t_find_s hm k)))

#restart-solver
#push-options "--z3rlimit 400"
let hashMap_try_resize_s_simpl_lem #t hm =
  let capacity = length hm.slots in
  let (divid, divis) = hm.max_load_factor in
  if capacity <= (usize_max / 2) / divid then
    begin
    let ncapacity : usize = capacity * 2 in
    assert(ncapacity * divid <= usize_max);
    assert(hashMap_t_len_s hm = hm.max_load + 1);
    new_max_load_lem (hashMap_t_len_s hm) capacity divid divis;
    hashMap_new_with_capacity_lem t ncapacity divid divis;
    match hashMap_new_with_capacity t ncapacity divid divis with
    | Fail _ -> ()
    | Return ntable ->
      let slots = hm.slots in
      let al = flatten (slots_t_v slots) in
      // Proving that: length al = hm.num_entries
      assert(al == flatten (map slot_t_v slots));
      assert(al == flatten (map list_t_v slots));
      assert(hashMap_t_al_v hm == flatten (hashMap_t_v hm));
      assert(hashMap_t_al_v hm == flatten (map list_t_v hm.slots));
      assert(al == hashMap_t_al_v hm);
      assert(hashMap_t_base_inv ntable);
      assert(length al = hm.num_entries);
      assert(length al <= usize_max);
      hashMap_t_base_inv_implies_assoc_list_lem hm;
      assert(assoc_list_inv al);
      assert(hashMap_t_len_s ntable = 0);
      assert(forall (k:key). hashMap_t_find_s ntable k  == None);
      hashMap_move_elements_lem t ntable hm.slots;
      match hashMap_move_elements t ntable hm.slots 0 with
      | Fail _ -> ()
      | Return (ntable', _) ->
        hashMap_is_assoc_list_lem hm;
        assert(hashMap_is_assoc_list hm (hashMap_t_al_v hm));
        let hm' =
          { hm with slots = ntable'.slots;
                    max_load = ntable'.max_load }
        in
        assert(hashMap_t_base_inv ntable');
        assert(hashMap_t_base_inv hm');
        assert(hashMap_t_len_s hm' = hashMap_t_len_s hm);
        new_max_load_lem (hashMap_t_len_s hm') capacity divid divis;
        assert(hashMap_t_len_s hm' <= hm'.max_load); // Requires a lemma
        assert(hashMap_t_inv hm')
    end
  else
    begin
    gt_lem2 capacity 2 divid usize_max;
    assert(capacity * 2 * divid > usize_max)
    end
#pop-options

let hashMap_t_same_bindings  (#t : Type0) (hm hm' : hashMap_t_nes t) : Type0 =
  forall (k:key). hashMap_t_find_s hm k == hashMap_t_find_s hm' k

/// The final lemma about [try_resize]
val hashMap_try_resize_lem (#t : Type0) (hm : hashMap_t t) :
  Lemma
  (requires (
    hashMap_t_base_inv hm /\
    // However, the "full" invariant is broken, as we call [try_resize]
    // only if the current number of entries is > the max load.
    // 
    // There are two situations:
    // - either we just reached the max load
    // - or we were already saturated and can't resize
    (let (dividend, divisor) = hm.max_load_factor in
     hm.num_entries == hm.max_load + 1 \/
     length hm.slots * 2 * dividend > usize_max)))
  (ensures (
    match hashMap_try_resize t hm with
    | Fail _ -> False
    | Return hm' ->
      // The full invariant is now satisfied (the full invariant is "base
      // invariant" + the map is not overloaded (or can't be resized because
      // already too big)
      hashMap_t_inv hm' /\
      // The length is the same
      hashMap_t_len_s hm' = hashMap_t_len_s hm /\
      // It contains the same bindings as the initial map
      hashMap_t_same_bindings hm' hm))

let hashMap_try_resize_lem #t hm =
  hashMap_try_resize_lem_refin t hm;
  hashMap_try_resize_s_simpl_lem hm

(*** insert *)

/// The high-level model (very close to the original function: we don't need something
/// very high level, just to clean it a bit)
let hashMap_insert_s
  (#t : Type0) (self : hashMap_t t) (key : usize) (value : t) :
  result (hashMap_t t) =
  match hashMap_insert_no_resize t self key value with
  | Fail e -> Fail e
  | Return hm' ->
    if hashMap_t_len_s hm' > hm'.max_load then
      hashMap_try_resize t hm'
    else Return hm'

val hashMap_insert_lem_refin
  (t : Type0) (self : hashMap_t t) (key : usize) (value : t) :
  Lemma (requires True)
  (ensures (
    match hashMap_insert t self key value,
          hashMap_insert_s self key value
    with
    | Fail _, Fail _ -> True
    | Return hm1, Return hm2 -> hm1 == hm2
    | _ -> False))

let hashMap_insert_lem_refin t self key value = ()

/// Helper
let hashMap_insert_bindings_lem
  (t : Type0) (self : hashMap_t_nes t) (key : usize) (value : t)
  (hm' hm'' : hashMap_t_nes t) :
  Lemma
  (requires (
     hashMap_s_updated_binding (hashMap_t_v self) key
                                (Some value) (hashMap_t_v hm') /\
     hashMap_t_same_bindings hm' hm''))
  (ensures (
     hashMap_s_updated_binding (hashMap_t_v self) key
                                (Some value) (hashMap_t_v hm'')))
  = ()

val hashMap_insert_lem_aux
  (#t : Type0) (self : hashMap_t t) (key : usize) (value : t) :
  Lemma (requires (hashMap_t_inv self))
  (ensures (
    match hashMap_insert t self key value with
    | Fail _ ->
      // We can fail only if:
      // - the key is not in the map and we need to add it
      // - we are already saturated
      hashMap_t_len_s self = usize_max /\
      None? (hashMap_t_find_s self key)
    | Return hm' ->
      // The invariant is preserved
      hashMap_t_inv hm' /\
      // [key] maps to [value] and the other bindings are preserved
      hashMap_s_updated_binding (hashMap_t_v self) key (Some value) (hashMap_t_v hm') /\
      // The length is incremented, iff we inserted a new key
      (match hashMap_t_find_s self key with
       | None -> hashMap_t_len_s hm' = hashMap_t_len_s self + 1
       | Some _ -> hashMap_t_len_s hm' = hashMap_t_len_s self)))

#restart-solver
#push-options "--z3rlimit 200"
let hashMap_insert_lem_aux #t self key value =
  hashMap_insert_no_resize_lem_s t self key value;
  hashMap_insert_no_resize_s_lem (hashMap_t_v self) key value;
  match hashMap_insert_no_resize t self key value with
  | Fail _ -> ()
  | Return hm' ->
    // Expanding the post of [hashMap_insert_no_resize_lem_s]
    let self_v = hashMap_t_v self in
    let hm'_v = Return?.v (hashMap_insert_no_resize_s self_v key value) in
    assert(hashMap_t_base_inv hm');
    assert(hashMap_t_same_params hm' self);
    assert(hashMap_t_v hm' == hm'_v);
    assert(hashMap_s_len hm'_v == hashMap_t_len_s hm');
    // Expanding the post of [hashMap_insert_no_resize_s_lem]
    assert(insert_post self_v key value hm'_v);
    // Expanding [insert_post]
    assert(hashMap_s_inv hm'_v);
    assert(
      match hashMap_s_find self_v key with
      | None -> hashMap_s_len hm'_v = hashMap_s_len self_v + 1
      | Some _ -> hashMap_s_len hm'_v = hashMap_s_len self_v);
    if hashMap_t_len_s hm' > hm'.max_load then
      begin
      hashMap_try_resize_lem hm';
      // Expanding the post of [hashMap_try_resize_lem]
      let hm'' = Return?.v (hashMap_try_resize t hm') in
      assert(hashMap_t_inv hm'');
      let hm''_v = hashMap_t_v hm'' in
      assert(forall k. hashMap_t_find_s hm'' k == hashMap_t_find_s hm' k);
      assert(hashMap_t_len_s hm'' = hashMap_t_len_s hm'); // TODO
      // Proving the post
      assert(hashMap_t_inv hm'');
      hashMap_insert_bindings_lem t self key value hm' hm'';
      assert(
        match hashMap_t_find_s self key with
         | None -> hashMap_t_len_s hm'' = hashMap_t_len_s self + 1
         | Some _ -> hashMap_t_len_s hm'' = hashMap_t_len_s self)
      end
    else ()
#pop-options

let hashMap_insert_lem #t self key value =
  hashMap_insert_lem_aux #t self key value

(*** contains_key *)

(**** contains_key_in_list *)

val hashMap_contains_key_in_list_lem
  (#t : Type0) (key : usize) (ls : list_t t) :
  Lemma
  (ensures (
    match hashMap_contains_key_in_list t key ls with
    | Fail _ -> False
    | Return b ->
      b = Some? (slot_t_find_s key ls)))


#push-options "--fuel 1"
let rec hashMap_contains_key_in_list_lem #t key ls =
  match ls with
  | List_Cons ckey x ls0 ->
    let b = ckey = key in
    if b
    then ()
    else
      begin
      hashMap_contains_key_in_list_lem key ls0;
      match hashMap_contains_key_in_list t key ls0 with
      | Fail _ -> ()
      | Return b0 -> ()
      end
  | List_Nil -> ()
#pop-options

(**** contains_key *)

val hashMap_contains_key_lem_aux
  (#t : Type0) (self : hashMap_t_nes t) (key : usize) :
  Lemma
  (ensures (
    match hashMap_contains_key t self key with
    | Fail _ -> False
    | Return b -> b = Some? (hashMap_t_find_s self key)))

let hashMap_contains_key_lem_aux #t self key =
  begin match hash_key key with
  | Fail _ -> ()
  | Return i ->
    let v = self.slots in
    let i0 = alloc_vec_Vec_len (list_t t) v in
    begin match usize_rem i i0 with
    | Fail _ -> ()
    | Return hash_mod ->
      begin match alloc_vec_Vec_index_usize v hash_mod with
      | Fail _ -> ()
      | Return l ->
        hashMap_contains_key_in_list_lem key l;
        begin match hashMap_contains_key_in_list t key l with
        | Fail _ -> ()
        | Return b -> ()
        end
      end
    end
  end

/// The lemma in the .fsti
let hashMap_contains_key_lem #t self key =
  hashMap_contains_key_lem_aux #t self key

(*** get *)

(**** get_in_list *)

val hashMap_get_in_list_lem
  (#t : Type0) (key : usize) (ls : list_t t) :
  Lemma
  (ensures (
    match hashMap_get_in_list t key ls, slot_t_find_s key ls with
    | Fail _, None -> True
    | Return x, Some x' -> x == x'
    | _ -> False))

#push-options "--fuel 1"
let rec hashMap_get_in_list_lem #t key ls =
  begin match ls with
  | List_Cons ckey cvalue ls0 ->
    let b = ckey = key in
    if b
    then ()
    else
      begin
      hashMap_get_in_list_lem key ls0;
      match hashMap_get_in_list t key ls0 with
      | Fail _ -> ()
      | Return x -> ()
      end
  | List_Nil -> ()
  end
#pop-options

(**** get *)

val hashMap_get_lem_aux
  (#t : Type0) (self : hashMap_t_nes t) (key : usize) :
  Lemma
  (ensures (
    match hashMap_get t self key, hashMap_t_find_s self key with
    | Fail _, None -> True
    | Return x, Some x' -> x == x'
    | _ -> False))

let hashMap_get_lem_aux #t self key =
  begin match hash_key key with
  | Fail _ -> ()
  | Return i ->
    let v = self.slots in
    let i0 = alloc_vec_Vec_len (list_t t) v in
    begin match usize_rem i i0 with
    | Fail _ -> ()
    | Return hash_mod ->
      begin match alloc_vec_Vec_index_usize v hash_mod with
      | Fail _ -> ()
      | Return l ->
        begin
        hashMap_get_in_list_lem key l;
        match hashMap_get_in_list t key l with
        | Fail _ -> ()
        | Return x -> ()
        end
      end
    end
  end

/// .fsti
let hashMap_get_lem #t self key = hashMap_get_lem_aux #t self key

(*** get_mut'fwd *)


(**** get_mut_in_list'fwd *)

val hashMap_get_mut_in_list_loop_lem
  (#t : Type0) (ls : list_t t) (key : usize) :
  Lemma
  (ensures (
    match hashMap_get_mut_in_list_loop t ls key, slot_t_find_s key ls with
    | Fail _, None -> True
    | Return x, Some x' -> x == x'
    | _ -> False))

#push-options "--fuel 1"
let rec hashMap_get_mut_in_list_loop_lem #t ls key =
  begin match ls with
  | List_Cons ckey cvalue ls0 ->
    let b = ckey = key in
    if b
    then ()
    else
      begin
      hashMap_get_mut_in_list_loop_lem ls0 key;
      match hashMap_get_mut_in_list_loop t ls0 key with
      | Fail _ -> ()
      | Return x -> ()
      end
  | List_Nil -> ()
  end
#pop-options

(**** get_mut'fwd *)

val hashMap_get_mut_lem_aux
  (#t : Type0) (self : hashMap_t_nes t) (key : usize) :
  Lemma
  (ensures (
    match hashMap_get_mut t self key, hashMap_t_find_s self key with
    | Fail _, None -> True
    | Return x, Some x' -> x == x'
    | _ -> False))

let hashMap_get_mut_lem_aux #t self key =
  begin match hash_key key with
  | Fail _ -> ()
  | Return i ->
    let v = self.slots in
    let i0 = alloc_vec_Vec_len (list_t t) v in
    begin match usize_rem i i0 with
    | Fail _ -> ()
    | Return hash_mod ->
      begin match alloc_vec_Vec_index_usize v hash_mod with
      | Fail _ -> ()
      | Return l ->
        begin
        hashMap_get_mut_in_list_loop_lem l key;
        match hashMap_get_mut_in_list_loop t l key with
        | Fail _ -> ()
        | Return x -> ()
        end
      end
    end
  end

let hashMap_get_mut_lem #t self key =
  hashMap_get_mut_lem_aux #t self key

(*** get_mut'back *)

(**** get_mut_in_list'back *)

val hashMap_get_mut_in_list_loop_back_lem
  (#t : Type0) (ls : list_t t) (key : usize) (ret : t) :
  Lemma
  (requires (Some? (slot_t_find_s key ls)))
  (ensures (
    match hashMap_get_mut_in_list_loop_back t ls key ret with
    | Fail _ -> False
    | Return ls' -> list_t_v ls' == find_update (same_key key) (list_t_v ls) (key,ret)
    | _ -> False))

#push-options "--fuel 1"
let rec hashMap_get_mut_in_list_loop_back_lem #t ls key ret =
  begin match ls with
  | List_Cons ckey cvalue ls0 ->
    let b = ckey = key in
    if b
    then let ls1 = List_Cons ckey ret ls0 in ()
    else
      begin
      hashMap_get_mut_in_list_loop_back_lem ls0 key ret;
      match hashMap_get_mut_in_list_loop_back t ls0 key ret with
      | Fail _ -> ()
      | Return l -> let ls1 = List_Cons ckey cvalue l in ()
      end
  | List_Nil -> ()
  end
#pop-options

(**** get_mut'back *)

/// Refinement lemma
val hashMap_get_mut_back_lem_refin
  (#t : Type0) (self : hashMap_t t{length self.slots > 0})
  (key : usize) (ret : t) :
  Lemma
  (requires (Some? (hashMap_t_find_s self key)))
  (ensures (
    match hashMap_get_mut_back t self key ret with
    | Fail _ -> False
    | Return hm' ->
      hashMap_t_v hm' == hashMap_insert_no_fail_s (hashMap_t_v self) key ret))

let hashMap_get_mut_back_lem_refin #t self key ret =
  begin match hash_key key with
  | Fail _ -> ()
  | Return i ->
    let i0 = self.num_entries in
    let p = self.max_load_factor in
    let i1 = self.max_load in
    let v = self.slots in
    let i2 = alloc_vec_Vec_len (list_t t) v in
    begin match usize_rem i i2 with
    | Fail _ -> ()
    | Return hash_mod ->
      begin match alloc_vec_Vec_index_usize v hash_mod with
      | Fail _ -> ()
      | Return l ->
        begin
        hashMap_get_mut_in_list_loop_back_lem l key ret;
        match hashMap_get_mut_in_list_loop_back t l key ret with
        | Fail _ -> ()
        | Return l0 ->
          begin match alloc_vec_Vec_update_usize v hash_mod l0 with
          | Fail _ -> ()
          | Return v0 -> let self0 = MkhashMap_t i0 p i1 v0 in ()
          end
        end
      end
    end
  end

/// Final lemma
val hashMap_get_mut_back_lem_aux
  (#t : Type0) (hm : hashMap_t t)
  (key : usize) (ret : t) :
  Lemma
  (requires (
    hashMap_t_inv hm /\
    Some? (hashMap_t_find_s hm key)))
  (ensures (
    match hashMap_get_mut_back t hm key ret with
    | Fail _ -> False
    | Return hm' ->
      // Functional spec
      hashMap_t_v hm' == hashMap_insert_no_fail_s (hashMap_t_v hm) key ret /\
     // The invariant is preserved
     hashMap_t_inv hm' /\
     // The length is preserved
     hashMap_t_len_s hm' = hashMap_t_len_s hm /\
     // [key] maps to [value]
     hashMap_t_find_s hm' key == Some ret /\
     // The other bindings are preserved
     (forall k'. k' <> key ==> hashMap_t_find_s hm' k' == hashMap_t_find_s hm k')))

let hashMap_get_mut_back_lem_aux #t hm key ret =
  let hm_v = hashMap_t_v hm in
  hashMap_get_mut_back_lem_refin hm key ret;
  match hashMap_get_mut_back t hm key ret with
  | Fail _ -> assert(False)
  | Return hm' ->
    hashMap_insert_no_fail_s_lem hm_v key ret

/// .fsti
let hashMap_get_mut_back_lem #t hm key ret = hashMap_get_mut_back_lem_aux hm key ret

(*** remove'fwd *)

val hashMap_remove_from_list_lem
  (#t : Type0) (key : usize) (ls : list_t t) :
  Lemma
  (ensures (
    match hashMap_remove_from_list t key ls with
    | Fail _ -> False
    | Return opt_x ->
      opt_x == slot_t_find_s key ls /\
      (Some? opt_x ==> length (slot_t_v ls) > 0)))

#push-options "--fuel 1"
let rec hashMap_remove_from_list_lem #t key ls =
  begin match ls with
  | List_Cons ckey x tl ->
    let b = ckey = key in
    if b
    then
      let mv_ls = core_mem_replace (list_t t) (List_Cons ckey x tl) List_Nil in
      begin match mv_ls with
      | List_Cons i cvalue tl0 -> ()
      | List_Nil -> ()
      end
    else
      begin
      hashMap_remove_from_list_lem key tl;
      match hashMap_remove_from_list t key tl with
      | Fail _ -> ()
      | Return opt -> ()
      end
  | List_Nil -> ()
  end
#pop-options

val hashMap_remove_lem_aux
  (#t : Type0) (self : hashMap_t t) (key : usize) :
  Lemma
  (requires (
    // We need the invariant to prove that upon decrementing the entries counter,
    // the counter doesn't become negative
    hashMap_t_inv self))
  (ensures (
    match hashMap_remove t self key with
    | Fail _ -> False
    | Return opt_x -> opt_x == hashMap_t_find_s self key))

let hashMap_remove_lem_aux #t self key =
  begin match hash_key key with
  | Fail _ -> ()
  | Return i ->
    let i0 = self.num_entries in
    let v = self.slots in
    let i1 = alloc_vec_Vec_len (list_t t) v in
    begin match usize_rem i i1 with
    | Fail _ -> ()
    | Return hash_mod ->
      begin match alloc_vec_Vec_index_usize v hash_mod with
      | Fail _ -> ()
      | Return l ->
        begin
        hashMap_remove_from_list_lem key l;
        match hashMap_remove_from_list t key l with
        | Fail _ -> ()
        | Return x ->
          begin match x with
          | None -> ()
          | Some x0 ->
            begin
            assert(l == index v hash_mod);
            assert(length (list_t_v #t l) > 0);
            length_flatten_index (hashMap_t_v self) hash_mod;
            match usize_sub i0 1 with
            | Fail _ -> ()
            | Return _ -> ()
            end
          end
        end
      end
    end
  end

/// .fsti
let hashMap_remove_lem #t self key = hashMap_remove_lem_aux #t self key

(*** remove'back *)

(**** Refinement proofs *)

/// High-level model for [remove_from_list'back]
let hashMap_remove_from_list_s
  (#t : Type0) (key : usize) (ls : slot_s t) :
  slot_s t =
  filter_one (not_same_key key) ls

/// Refinement lemma
val hashMap_remove_from_list_back_lem_refin
  (#t : Type0) (key : usize) (ls : list_t t) :
  Lemma
  (ensures (
    match hashMap_remove_from_list_back t key ls with
    | Fail _ -> False
    | Return ls' ->
      list_t_v ls' == hashMap_remove_from_list_s key (list_t_v ls) /\
      // The length is decremented, iff the key was in the slot
      (let len = length (list_t_v ls) in
       let len' = length (list_t_v ls') in
       match slot_s_find key (list_t_v ls) with
       | None -> len = len'
       | Some _ -> len = len' + 1)))

#push-options "--fuel 1"
let rec hashMap_remove_from_list_back_lem_refin #t key ls =
  begin match ls with
  | List_Cons ckey x tl ->
    let b = ckey = key in
    if b
    then
      let mv_ls = core_mem_replace (list_t t) (List_Cons ckey x tl) List_Nil in
      begin match mv_ls with
      | List_Cons i cvalue tl0 -> ()
      | List_Nil -> ()
      end
    else
      begin
      hashMap_remove_from_list_back_lem_refin key tl;
      match hashMap_remove_from_list_back t key tl with
      | Fail _ -> ()
      | Return l -> let ls0 = List_Cons ckey x l in ()
      end
  | List_Nil -> ()
  end
#pop-options

/// High-level model for [remove_from_list'back]
let hashMap_remove_s
  (#t : Type0) (self : hashMap_s_nes t) (key : usize) :
  hashMap_s t =
  let len = length self in
  let hash = hash_mod_key key len in
  let slot = index self hash in
  let slot' = hashMap_remove_from_list_s key slot in
  list_update self hash slot'

/// Refinement lemma
val hashMap_remove_back_lem_refin
  (#t : Type0) (self : hashMap_t_nes t) (key : usize) :
  Lemma
  (requires (
    // We need the invariant to prove that upon decrementing the entries counter,
    // the counter doesn't become negative
    hashMap_t_inv self))
  (ensures (
    match hashMap_remove_back t self key with
    | Fail _ -> False
    | Return hm' ->
      hashMap_t_same_params hm' self /\
      hashMap_t_v hm' == hashMap_remove_s (hashMap_t_v self) key /\
      // The length is decremented iff the key was in the map
      (let len = hashMap_t_len_s self in
       let len' = hashMap_t_len_s hm' in
       match hashMap_t_find_s self key with
       | None -> len = len'
       | Some _ -> len = len' + 1)))

let hashMap_remove_back_lem_refin #t self key =
  begin match hash_key key with
  | Fail _ -> ()
  | Return i ->
    let i0 = self.num_entries in
    let p = self.max_load_factor in
    let i1 = self.max_load in
    let v = self.slots in
    let i2 = alloc_vec_Vec_len (list_t t) v in
    begin match usize_rem i i2 with
    | Fail _ -> ()
    | Return hash_mod ->
      begin match alloc_vec_Vec_index_usize v hash_mod with
      | Fail _ -> ()
      | Return l ->
        begin
        hashMap_remove_from_list_lem key l;
        match hashMap_remove_from_list t key l with
        | Fail _ -> ()
        | Return x ->
          begin match x with
          | None ->
            begin
            hashMap_remove_from_list_back_lem_refin key l;
            match hashMap_remove_from_list_back t key l with
            | Fail _ -> ()
            | Return l0 ->
              begin
              length_flatten_update (slots_t_v v) hash_mod (list_t_v l0);
              match alloc_vec_Vec_update_usize v hash_mod l0 with
              | Fail _ -> ()
              | Return v0 -> ()
              end
            end
          | Some x0 ->
            begin
            assert(l == index v hash_mod);
            assert(length (list_t_v #t l) > 0);
            length_flatten_index (hashMap_t_v self) hash_mod;
            match usize_sub i0 1 with
            | Fail _ -> ()
            | Return i3 ->
              begin
              hashMap_remove_from_list_back_lem_refin key l;
              match hashMap_remove_from_list_back t key l with
              | Fail _ -> ()
              | Return l0 ->
                begin
                length_flatten_update (slots_t_v v) hash_mod (list_t_v l0);
                match alloc_vec_Vec_update_usize v hash_mod l0 with
                | Fail _ -> ()
                | Return v0 -> ()
                end
              end
            end
          end
        end
      end
    end
  end

(**** Invariants, high-level properties *)

val hashMap_remove_from_list_s_lem
  (#t : Type0) (k : usize) (slot : slot_s t) (len : usize{len > 0}) (i : usize) :
  Lemma
  (requires (slot_s_inv len i slot))
  (ensures (
    let slot' = hashMap_remove_from_list_s k slot in
    slot_s_inv len i slot' /\
    slot_s_find k slot' == None /\
    (forall (k':key{k' <> k}). slot_s_find k' slot' == slot_s_find k' slot) /\
    // This postcondition is necessary to prove that the invariant is preserved
    // in the recursive calls. This allows us to do the proof in one go.
    (forall (b:binding t). for_all (binding_neq b) slot ==> for_all (binding_neq b) slot')
  ))

#push-options "--fuel 1"
let rec hashMap_remove_from_list_s_lem #t key slot len i =
  match slot with
  | [] -> ()
  | (k',v) :: slot' ->
    if k' <> key then
      begin
      hashMap_remove_from_list_s_lem key slot' len i;
      let slot'' = hashMap_remove_from_list_s key slot' in
      assert(for_all (same_hash_mod_key len i) ((k',v)::slot''));
      assert(for_all (binding_neq (k',v)) slot'); // Triggers instanciation
      assert(for_all (binding_neq (k',v)) slot'')
      end
    else
      begin
      assert(for_all (binding_neq (k',v)) slot');
      for_all_binding_neq_find_lem key v slot'
      end
#pop-options

val hashMap_remove_s_lem
  (#t : Type0) (self : hashMap_s_nes t) (key : usize) :
  Lemma
  (requires (hashMap_s_inv self))
  (ensures (
    let hm' = hashMap_remove_s self key in
    // The invariant is preserved
    hashMap_s_inv hm' /\
    // We updated the binding
    hashMap_s_updated_binding self key None hm'))

let hashMap_remove_s_lem #t self key =
  let len = length self in
  let hash = hash_mod_key key len in
  let slot = index self hash in
  hashMap_remove_from_list_s_lem key slot len hash;
  let slot' = hashMap_remove_from_list_s key slot in
  let hm' = list_update self hash slot' in
  assert(hashMap_s_inv self)

/// Final lemma about [remove'back]
val hashMap_remove_back_lem_aux
  (#t : Type0) (self : hashMap_t t) (key : usize) :
  Lemma
  (requires (hashMap_t_inv self))
  (ensures (
    match hashMap_remove_back t self key with
    | Fail _ -> False
    | Return hm' ->
      hashMap_t_inv self /\
      hashMap_t_same_params hm' self /\
      // We updated the binding
      hashMap_s_updated_binding (hashMap_t_v self) key None (hashMap_t_v hm') /\
      hashMap_t_v hm' == hashMap_remove_s (hashMap_t_v self) key /\
      // The length is decremented iff the key was in the map
      (let len = hashMap_t_len_s self in
       let len' = hashMap_t_len_s hm' in
       match hashMap_t_find_s self key with
       | None -> len = len'
       | Some _ -> len = len' + 1)))

let hashMap_remove_back_lem_aux #t self key =
  hashMap_remove_back_lem_refin self key;
  hashMap_remove_s_lem (hashMap_t_v self) key

/// .fsti
let hashMap_remove_back_lem #t self key =
  hashMap_remove_back_lem_aux #t self key