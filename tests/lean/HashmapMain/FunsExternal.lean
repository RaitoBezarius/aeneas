-- [hashmap_main]: templates for the external functions.
import Base
import HashmapMain.Types
open Primitives
open hashmap_main

-- TODO: fill those bodies

/- [hashmap_main::hashmap_utils::deserialize] -/
def hashmap_utils.deserialize_fwd
  : State → Result (State × (hashmap_hash_map_t U64)) :=
  fun _ => .fail .panic

/- [hashmap_main::hashmap_utils::serialize] -/
def hashmap_utils.serialize_fwd
  : hashmap_hash_map_t U64 → State → Result (State × Unit) :=
  fun _ _ => .fail .panic
