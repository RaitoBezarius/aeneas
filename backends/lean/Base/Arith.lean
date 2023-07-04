/- This file contains tactics to solve arithmetic goals -/

import Lean
import Lean.Meta.Tactic.Simp
import Init.Data.List.Basic
import Mathlib.Tactic.RunCmd
import Mathlib.Tactic.Linarith
-- TODO: there is no Omega tactic for now - it seems it hasn't been ported yet
--import Mathlib.Tactic.Omega
import Base.Primitives

/-
Mathlib tactics:
- rcases: https://leanprover-community.github.io/mathlib_docs/tactics.html#rcases
- split_ifs: https://leanprover-community.github.io/mathlib_docs/tactics.html#split_ifs
- norm_num: https://leanprover-community.github.io/mathlib_docs/tactics.html#norm_num
- should we use linarith or omega?
- hint: https://leanprover-community.github.io/mathlib_docs/tactics.html#hint
- classical: https://leanprover-community.github.io/mathlib_docs/tactics.html#classical
-/

namespace List

  -- TODO: I could not find this function??
  @[simp] def flatten {a : Type u} : List (List a) → List a
  | [] => []
  | x :: ls => x ++ flatten ls

end List

namespace Lean

namespace LocalContext

  open Lean Lean.Elab Command Term Lean.Meta

  -- Small utility: return the list of declarations in the context, from
  -- the last to the first.
  def getAllDecls (lctx : Lean.LocalContext) : MetaM (List Lean.LocalDecl) :=
    lctx.foldrM (fun d ls => do let d ← instantiateLocalDeclMVars d; pure (d :: ls)) []

  -- Return the list of declarations in the context, but filter the
  -- declarations which are considered as implementation details
  def getDecls (lctx : Lean.LocalContext) : MetaM (List Lean.LocalDecl) := do
    let ls ← lctx.getAllDecls
    pure (ls.filter (fun d => not d.isImplementationDetail))

end LocalContext

end Lean

namespace Arith

open Primitives

--set_option pp.explicit true
--set_option pp.notation false
--set_option pp.coercions false

-- TODO: move
instance Vec.cast (a : Type): Coe (Vec a) (List a)  where coe := λ v => v.val

-- TODO: move
/- Remark: we can't write the following instance because of restrictions about
   the type class parameters (`ty` doesn't appear in the return type, which is
   forbidden):

   ```
   instance Scalar.cast (ty : ScalarTy) : Coe (Scalar ty) Int where coe := λ v => v.val
   ```
 -/
def Scalar.toInt {ty : ScalarTy} (x : Scalar ty) : Int := x.val

-- We use this type-class to test if an expression is a scalar (if we manage
-- to lookup an instance of this type-class, then it is)
class IsScalar (a : Type) where

instance (ty : ScalarTy) : IsScalar (Scalar ty) where

example (ty : ScalarTy) : IsScalar (Scalar ty) := inferInstance

-- Remark: I tried a version of the shape `HasProp {a : Type} (x : a)`
-- but the lookup didn't work
class HasProp (a : Type) where
  prop_ty : a → Prop
  prop : ∀ x:a, prop_ty x

instance (ty : ScalarTy) : HasProp (Scalar ty) where
  -- prop_ty is inferred
  prop := λ x => And.intro x.hmin x.hmax

instance (a : Type) : HasProp (Vec a) where
  prop_ty := λ v => v.val.length ≤ Scalar.max ScalarTy.Usize
  prop := λ ⟨ _, l ⟩ => l

open Lean Lean.Elab Command Term Lean.Meta

-- Return true if the expression is a scalar expression
def isScalarExpr (e : Expr) : MetaM Bool := do
  -- Try to convert the expression to a scalar
  -- TODO: I tried to do it with Lean.Meta.mkAppM but it didn't work: how
  -- do we allow Lean to perform (controlled) unfoldings for instantiation
  -- purposes?
  let r ← Lean.observing? do
    let ty ← Lean.Meta.inferType e
    let isScalar ← mkAppM `Arith.IsScalar #[ty]
    let isScalar ← trySynthInstance isScalar
    match isScalar with
    | LOption.some x => some x
    | _ => none
  match r with
  | .some _ => pure true
  | _       => pure false

-- Return an instance of `HasProp` for `e` if it has some
def lookupHasProp (e : Expr) : MetaM (Option Expr) := do
  logInfo f!"lookupHasProp"
  -- TODO: do we need Lean.observing?
  -- This actually eliminates the error messages
  Lean.observing? do
    logInfo f!"lookupHasProp: observing"
    let ty ← Lean.Meta.inferType e
    let hasProp ← mkAppM ``Arith.HasProp #[ty]
    let hasPropInst ← trySynthInstance hasProp
    match hasPropInst with
    | LOption.some i =>
      logInfo m!"Found HasProp instance"
      let i_prop ← mkProjection i `prop
      some (← mkAppM' i_prop #[e])
    | _ => none

-- Auxiliary function for `collectHasPropInstances`
private partial def collectHasPropInstancesAux (hs : HashSet Expr) (e : Expr) : MetaM (HashSet Expr) := do
  -- We do it in a very simpler manner: we deconstruct applications,
  -- and recursively explore the sub-expressions. Note that we do
  -- not go inside foralls and abstractions (should we?).
  e.withApp fun f args => do
    let hasPropInst ← lookupHasProp f
    let hs := Option.getD (hasPropInst.map hs.insert) hs
    let hs ← args.foldlM collectHasPropInstancesAux hs
    pure hs

-- Explore a term and return the instances of `HasProp` found for the sub-expressions
def collectHasPropInstances (e : Expr) : MetaM (HashSet Expr) :=
  collectHasPropInstancesAux HashSet.empty e

-- Explore a term and return the set of scalar expressions found inside
partial def collectScalarExprsAux (hs : HashSet Expr) (e : Expr) : MetaM (HashSet Expr) := do
  -- We do it in a very simpler manner: we deconstruct applications,
  -- and recursively explore the sub-expressions. Note that we do
  -- not go inside foralls and abstractions (should we?).
  e.withApp fun f args => do
    let hs ← if ← isScalarExpr f then pure (hs.insert f) else pure hs
    let hs ← args.foldlM collectScalarExprsAux hs
    pure hs

-- Explore a term and return the list of scalar expressions found inside
def collectScalarExprs (e : Expr) : MetaM (HashSet Expr) :=
  collectScalarExprsAux HashSet.empty e

-- Collect the scalar expressions in the context
def getScalarExprsFromMainCtx : Tactic.TacticM (HashSet Expr) := do
  Lean.Elab.Tactic.withMainContext do
  -- Get the local context
  let ctx ← Lean.MonadLCtx.getLCtx
  -- Just a matter of precaution
  let ctx ← instantiateLCtxMVars ctx
  -- Initialize the hashset
  let hs := HashSet.empty
  -- Explore the declarations
  let decls ← ctx.getDecls
  let hs ← decls.foldlM (fun hs d => collectScalarExprsAux hs d.toExpr) hs
  -- Return
  pure hs

-- Collect the instances of `HasProp` for the subexpressions in the context
def getHasPropInstancesFromMainCtx : Tactic.TacticM (HashSet Expr) := do
  Lean.Elab.Tactic.withMainContext do
  -- Get the local context
  let ctx ← Lean.MonadLCtx.getLCtx
  -- Just a matter of precaution
  let ctx ← instantiateLCtxMVars ctx
  -- Initialize the hashset
  let hs := HashSet.empty
  -- Explore the declarations
  let decls ← ctx.getDecls
  let hs ← decls.foldlM (fun hs d => collectHasPropInstancesAux hs d.toExpr) hs
  -- Return
  pure hs

elab "list_scalar_exprs" : tactic => do
  logInfo m!"Listing scalar expressions"
  let hs ← getScalarExprsFromMainCtx
  hs.forM fun e => do
    logInfo m!"+ Scalar expression: {e}"

example (x y : U32) (z : Usize) : True := by
  list_scalar_exprs
  simp

elab "display_has_prop_instances" : tactic => do
  logInfo m!"Displaying the HasProp instances"
  let hs ← getHasPropInstancesFromMainCtx
  hs.forM fun e => do
    logInfo m!"+ HasProp instance: {e}"

example (x : U32) : True := by
  let i : HasProp U32 := inferInstance
  have p := @HasProp.prop _ i x
  simp only [HasProp.prop_ty] at p
  display_has_prop_instances
  simp

elab "list_local_decls_1" : tactic =>
  Lean.Elab.Tactic.withMainContext do
  -- Get the local context
  let ctx ← Lean.MonadLCtx.getLCtx
  let ctx ← instantiateLCtxMVars ctx
  let decls ← ctx.getDecls
  -- Filter the scalar expressions
  let decls ← decls.filterMapM fun decl: Lean.LocalDecl => do
    let declExpr := decl.toExpr
    let declName := decl.userName
    let declType ← Lean.Meta.inferType declExpr
    dbg_trace f!"+ local decl: name: {declName} | expr: {declExpr} | ty: {declType}"
    -- Try to convert the expression to a scalar
    -- TODO: I tried to do it with Lean.Meta.mkAppM but it didn't work: how
    -- do we allow Lean to perform (controlled) unfoldings for instantiation
    -- purposes?
    let r ← Lean.observing? do
      let isScalar ← mkAppM `Arith.IsScalar #[declType]
      let isScalar ← trySynthInstance isScalar
      match isScalar with
      | LOption.some x => some x
      | _ => none
    match r with
    | .some _ => dbg_trace f!"  Scalar expression"; pure r
    | _       => dbg_trace f!"  Not a scalar"; pure .none
  pure ()

def evalAddDecl (name : Name) (val : Expr) (type : Expr) (asLet : Bool := false) : Tactic.TacticM Unit :=
  -- I don't think we need that
  Lean.Elab.Tactic.withMainContext do
  -- Insert the new declaration
  let withDecl := if asLet then withLetDecl name type val else withLocalDeclD name type
  withDecl fun nval => do
    -- For debugging
    let lctx ← Lean.MonadLCtx.getLCtx
    let fid := nval.fvarId!
    let decl := lctx.get! fid
        -- Remark: logInfo instantiates the mvars (contrary to dbg_trace):
    logInfo m!"  new decl: \"{decl.userName}\" ({nval}) : {decl.type} := {decl.value}"
    --
    -- Tranform the main goal `?m0` to `let x = nval in ?m1`
    let mvarId ← Tactic.getMainGoal
    let newMVar ← mkFreshExprSyntheticOpaqueMVar (← mvarId.getType)
    let newVal ← mkLetFVars #[nval] newMVar
    -- There are two cases:
    -- - asLet is true: newVal is `let $name := $val in $newMVar`
    -- - asLet is false: ewVal is `λ $name => $newMVar`
    --   We need to apply it to `val`
    let newVal := if asLet then newVal else mkAppN newVal #[val]
    -- Focus on the current goal
    Tactic.focus do
    -- Assign the main goal.
    -- We must do this *after* we focused on the current goal, because
    -- after we assigned the meta variable the goal is considered as solved
    mvarId.assign newVal
    -- Replace the list of goals with the new goal - we can do this because
    -- we focused on the current goal
    Lean.Elab.Tactic.setGoals [newMVar.mvarId!]

def evalAddDeclSyntax (name : Name) (val : Syntax) (asLet : Bool := false) : Tactic.TacticM Unit :=
  -- I don't think we need that
  Lean.Elab.Tactic.withMainContext do
  --
  let val ← elabTerm val .none
  let type ← inferType val
  -- In some situations, the type will be left as a metavariable (for instance,
  -- if the term is `3`, Lean has the choice between `Nat` and `Int` and will
  -- not choose): we force the instantiation of the meta-variable
  synthesizeSyntheticMVarsUsingDefault
  --
  evalAddDecl name val type asLet

elab "custom_let " n:ident " := " v:term : tactic =>
  evalAddDeclSyntax n.getId v (asLet := true)

elab "custom_have " n:ident " := " v:term : tactic =>
  evalAddDeclSyntax n.getId v (asLet := false)

example : Nat := by
  custom_let x := 4
  custom_have y := 4
  apply y

example (x : Bool) : Nat := by
  cases x <;> custom_let x := 3 <;> apply x

-- Lookup the instances of `HasProp for all the sub-expressions in the context,
-- and introduce the corresponding assumptions
elab "intro_has_prop_instances" : tactic => do
  logInfo m!"Introducing the HasProp instances"
  let hs ← getHasPropInstancesFromMainCtx
  hs.forM fun e => do
    let type ← inferType e
    let name := `h
    evalAddDecl name e type (asLet := false)
    -- Simplify to unfold the `prop_ty` projector
    let simpTheorems ← Tactic.simpOnlyBuiltins.foldlM (·.addConst ·) ({} : SimpTheorems)
    -- Add the equational theorem for `HashProp'.prop_ty`
    let simpTheorems ← simpTheorems.addDeclToUnfold ``HasProp.prop_ty
    let congrTheorems ← getSimpCongrTheorems
    let ctx : Simp.Context := { simpTheorems := #[simpTheorems], congrTheorems }
    -- Where to apply the simplifier
    let loc := Tactic.Location.targets #[mkIdent name] false
    -- Apply the simplifier
    let _ ← Tactic.simpLocation ctx (discharge? := .none) loc
    pure ()

example (x y : U32) : x.val ≤ Scalar.max ScalarTy.U32 := by
  intro_has_prop_instances
  simp [*]

example {a: Type} (v : Vec a) : v.val.length ≤ Scalar.max ScalarTy.Usize := by
  intro_has_prop_instances
  simp_all [Scalar.max, Scalar.min]

-- A tactic to solve linear arithmetic goals
syntax "int_tac" : tactic
macro_rules
  | `(tactic| int_tac) =>
    `(tactic|
      intro_has_prop_instances;
      have := Scalar.cMin_bound ScalarTy.Usize;
      have := Scalar.cMin_bound ScalarTy.Isize;
      have := Scalar.cMax_bound ScalarTy.Usize;
      have := Scalar.cMax_bound ScalarTy.Isize;
      simp only [*, Scalar.max, Scalar.min, Scalar.cMin, Scalar.cMax] at *;
      linarith)

example (x y : U32) : x.val ≤ Scalar.max ScalarTy.U32 := by
  int_tac

example {a: Type} (v : Vec a) : v.val.length ≤ Scalar.max ScalarTy.Usize := by
  int_tac

end Arith