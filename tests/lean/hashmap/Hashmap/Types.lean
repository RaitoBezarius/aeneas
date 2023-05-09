-- THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS
-- [hashmap]: type definitions
import Base.Primitives

/- [hashmap::List] -/
inductive list_t (T : Type) :=
| Cons : Usize -> T -> list_t T -> list_t T
| Nil : list_t T

/- [hashmap::HashMap] -/
structure hash_map_t (T : Type) where
  hash_map_num_entries : Usize
  hash_map_max_load_factor : (Usize × Usize)
  hash_map_max_load : Usize
  hash_map_slots : Vec (list_t T)

