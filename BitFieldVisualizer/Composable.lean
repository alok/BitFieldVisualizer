import BitFieldVisualizer.Basic

/-!
# Composable BitField API

Design principles for maximum adoption:
1. Zero boilerplate for common cases (derive from types)
2. Type class based (extensible to any type)
3. Composable primitives (mix and match)
4. Works with proofs (show invariants)
-/

open Lean Widget ProofWidgets

/-! ## 1. Type class for anything visualizable as bits -/

/-- Any type that can be visualized as a bitfield (fixed width) -/
class ToBitField (α : Type) (n : outParam Nat) where
  toBitVec : α → BitVec n
  labels : BitFieldLabels n := BitFieldLabels.empty n

/-- Automatic instance for BitVec -/
instance : ToBitField (BitVec n) n where
  toBitVec := id

/-- Show any ToBitField type -/
def showBits {α : Type} {n : Nat} [inst : ToBitField α n] (x : α) (title : Option String := none) : Html :=
  showBitField (inst.toBitVec x) inst.labels title

/-! ## 2. Derive labels from structure fields -/

/-- A labeled bit with compile-time name -/
structure LBit (name : String) where
  val : Bool
  deriving Inhabited

/-- Pack labeled bits into a BitVec -/
class PackBits (α : Type) (n : Nat) where
  pack : α → BitVec n
  labels : BitFieldLabels n

/-! ## 3. Builder pattern for fluent configuration -/

/-- Configuration for bitfield display -/
structure BitFieldConfig where
  showHex : Bool := true
  showBinary : Bool := true
  showLegend : Bool := true
  showIndices : Bool := true
  msbFirst : Bool := true  -- MSB on left
  cellWidth : Nat := 28
  deriving Inhabited

/-- Builder for bitfield visualization -/
structure BitFieldBuilder (n : Nat) where
  value : BitVec n
  labels : BitFieldLabels n
  title : Option String
  config : BitFieldConfig

namespace BitFieldBuilder

def new (bv : BitVec n) : BitFieldBuilder n :=
  { value := bv
    labels := BitFieldLabels.empty n
    title := none
    config := default }

def withLabels (b : BitFieldBuilder n) (l : BitFieldLabels n) : BitFieldBuilder n :=
  { b with labels := l }

def withTitle (b : BitFieldBuilder n) (t : String) : BitFieldBuilder n :=
  { b with title := some t }

def noLegend (b : BitFieldBuilder n) : BitFieldBuilder n :=
  { b with config := { b.config with showLegend := false } }

def noHex (b : BitFieldBuilder n) : BitFieldBuilder n :=
  { b with config := { b.config with showHex := false } }

def lsbFirst (b : BitFieldBuilder n) : BitFieldBuilder n :=
  { b with config := { b.config with msbFirst := false } }

/-- Render with current config -/
def render (b : BitFieldBuilder n) : Html :=
  -- For now, delegate to existing renderer (could extend with config)
  showBitField b.value b.labels b.title

end BitFieldBuilder

/-! ## 4. Combinators for composing visualizations -/

/-- Stack visualizations vertically -/
def vstack (widgets : List Html) : Html :=
  Html.element "div" #[attr "style" "display: flex; flex-direction: column; gap: 8px"]
    widgets.toArray

/-- Stack visualizations horizontally -/
def hstack (widgets : List Html) : Html :=
  Html.element "div" #[attr "style" "display: flex; flex-direction: row; gap: 8px; align-items: flex-start"]
    widgets.toArray

/-- Add a label to any widget -/
def labeled (label : String) (widget : Html) : Html :=
  Html.element "div" #[] #[
    Html.element "div" #[attr "style" "font-weight: bold; margin-bottom: 4px"] #[.text label],
    widget
  ]

/-! ## 5. Quick macros for inline use -/

-- Usage: bits! 0xFF
-- Usage: bits! myValue "My Title"
-- These would need macro implementation

/-! ## 6. Integration with operations -/

/-- Show a binary operation with before/after -/
def showBinOp (name : String) (a b : BitVec n) (op : BitVec n → BitVec n → BitVec n) : Html :=
  let result := op a b
  vstack [
    labeled "A" (BitFieldBuilder.new a |>.render),
    Html.element "div" #[attr "style" "font-size: 16px; font-weight: bold; padding: 4px"] #[.text name],
    labeled "B" (BitFieldBuilder.new b |>.render),
    Html.element "div" #[attr "style" "font-size: 16px; padding: 4px"] #[.text "="],
    labeled "Result" (BitFieldBuilder.new result |>.render)
  ]

/-! ## 7. Proof integration - show invariants alongside values -/

/-- A value with an associated property shown -/
def withProperty (bv : BitVec n) (prop : String) (holds : Bool) : Html :=
  let color := if holds then "#4caf50" else "#c62828"
  vstack [
    BitFieldBuilder.new bv |>.render,
    Html.element "div" #[attr "style" s!"color: {color}; font-style: italic; padding: 4px"]
      #[.text s!"{if holds then "✓" else "✗"} {prop}"]
  ]

/-! ## Examples -/

-- Example: Simple use
#html showBits (0xAB : BitVec 8)

-- Example: Builder pattern
#html BitFieldBuilder.new (0xAB : BitVec 8)
  |>.withTitle "My Register"
  |>.noLegend
  |>.render

-- Example: Composed views
#html vstack [
  labeled "Before" (showBits (0x0F : BitVec 8)),
  labeled "After"  (showBits (0xF0 : BitVec 8))
]

-- Example: Side by side
#html hstack [
  labeled "Input" (showBits (0xAA : BitVec 8)),
  labeled "Mask"  (showBits (0x0F : BitVec 8)),
  labeled "Result" (showBits (0x0A : BitVec 8))
]

-- Example: With property
#html withProperty (0x04 : BitVec 8) "is power of 2" true

-- Example: Show operation
#html showBinOp "AND" (0xAA : BitVec 8) (0x0F : BitVec 8) (· &&& ·)

/-! ## Future: Derive macro for structures

```lean
-- Goal: Auto-generate labels from field names
@[derive_bitfield]
structure MyFlags where
  enabled : Bool    -- bit 0
  ready : Bool      -- bit 1
  error : Bool      -- bit 2
  overflow : Bool   -- bit 3

-- Would generate:
instance : ToBitField MyFlags where
  width := 4
  toBitVec f := ...
  labels := BitFieldLabels.fromList [
    (0, "enabled"), (1, "ready"), (2, "error"), (3, "overflow")
  ]

-- Then just:
#html showBits myFlags
```
-/
