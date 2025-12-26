import BitFieldVisualizer.Composable
import Lean.Elab.Deriving

/-!
# ToBitField Deriving Handler

Automatically generates `ToBitField` instances for structures with Bool fields.

## Usage

```lean
structure MyFlags where
  enabled : Bool
  ready : Bool
  error : Bool
  deriving ToBitField

-- Generates:
-- instance : ToBitField MyFlags 3 where
--   toBitVec f := packBools ![f.enabled, f.ready, f.error]
--   labels := BitFieldLabels.fromList [(0, "enabled"), (1, "ready"), (2, "error")]
```
-/

/-- Pack a list of bools into a Nat (LSB first: index 0 = bit 0) -/
def packBoolsAux (bs : List Bool) (acc : Nat) (i : Nat) : Nat :=
  match bs with
  | [] => acc
  | b :: rest => packBoolsAux rest (if b then acc ||| (1 <<< i) else acc) (i + 1)

namespace BitFieldVisualizer.Derive

open Lean Elab Command Meta Term

/-- Check if a type is Bool -/
def isBoolType (e : Expr) : MetaM Bool := do
  let e ← whnf e
  return e.isConstOf ``Bool

/-- Get field names and types from a structure -/
def getStructFieldInfo (structName : Name) : MetaM (Array (Name × Expr)) := do
  let env ← getEnv
  let fields := getStructureFields env structName
  let info ← getConstInfoInduct structName
  let ctorName := info.ctors.head!
  let ctorInfo ← getConstInfoCtor ctorName
  -- Get the constructor type and extract field types
  forallTelescopeReducing ctorInfo.type fun args _ => do
    -- Skip parameters (first info.numParams args)
    let fieldArgs := args[info.numParams:]
    let mut result := #[]
    for i in [:fields.size] do
      let fieldName := fields[i]!
      let fieldType ← inferType fieldArgs[i]!
      result := result.push (fieldName, fieldType)
    return result

/-- The deriving handler for ToBitField -/
def mkToBitFieldInstanceHandler (declNames : Array Name) : CommandElabM Bool := do
  if declNames.size ≠ 1 then
    return false
  let declName := declNames[0]!

  -- Check it's a structure
  let env ← getEnv
  unless isStructure env declName do
    logWarning m!"ToBitField deriving only works on structures, not {declName}"
    return false

  -- Get field info
  let fieldInfo ← liftTermElabM <| getStructFieldInfo declName

  -- Check all fields are Bool
  for (fieldName, fieldType) in fieldInfo do
    let isBool ← liftTermElabM <| isBoolType fieldType
    unless isBool do
      logWarning m!"ToBitField deriving requires all fields to be Bool, but {fieldName} has type {fieldType}"
      return false

  let numFields := fieldInfo.size
  if numFields == 0 then
    logWarning m!"ToBitField deriving requires at least one field"
    return false

  -- Generate the instance
  let structIdent := mkIdent declName
  let nLit := Syntax.mkNumLit (toString numFields)

  -- Build the list of field accessors: [f.field1, f.field2, ...]
  let fieldAccessors ← fieldInfo.mapM fun (fieldName, _) => do
    let fieldIdent := mkIdent fieldName
    `(f.$fieldIdent:ident)

  -- Build the list literal for BitVec.ofBoolListLE
  let boolListStx ← `([$[$fieldAccessors],*])

  -- Build the labels list: [(0, "field1"), (1, "field2"), ...]
  let labelPairs ← fieldInfo.mapIdxM fun idx (fieldName, _) => do
    let idxLit := Syntax.mkNumLit (toString idx)
    let nameLit := Syntax.mkStrLit fieldName.toString
    `(($idxLit, $nameLit))

  let labelsListStx ← `([$[$labelPairs],*])

  -- Build field list for documentation
  let bitDocs := (List.range numFields).zip fieldInfo.toList |>.map fun (i, (name, _)) => s!"- Bit {i}: `{name}`"
  let docString := s!"Auto-generated `ToBitField` instance for `{declName}`.

**Bit layout** (LSB first):
{String.intercalate "\n" bitDocs}

**Width**: {numFields} bits"

  -- Generate instance (doc will be added after)
  let cmd ← `(command|
    instance : ToBitField $structIdent $nLit where
      toBitVec := fun f => BitVec.ofNat $nLit (packBoolsAux $boolListStx 0 0)
      labels := BitFieldLabels.fromList $labelsListStx
  )

  trace[Elab.Deriving.ToBitField] "instance command:\n{cmd}"
  elabCommand cmd

  -- Add docstring to the generated instance
  let instName := declName ++ `instToBitField
  try
    addDocStringCore instName docString
  catch _ =>
    pure ()  -- Instance name might differ, that's ok

  return true

initialize
  registerDerivingHandler ``ToBitField mkToBitFieldInstanceHandler
  registerTraceClass `Elab.Deriving.ToBitField

end BitFieldVisualizer.Derive
