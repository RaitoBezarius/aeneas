-- THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS
-- [loops]: type definitions
import Base
open Primitives
namespace loops

/- [loops::List] -/
inductive List (T : Type) :=
| Cons : T → List T → List T
| Nil : List T

end loops
