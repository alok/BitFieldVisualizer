import BitFieldVisualizer.Basic

/-!
# Bitwise Operation Visualizer

Elaborator/macro demo that visualizes bitwise operations,
showing which bits were set (green) or cleared (red).
-/

open Lean Widget ProofWidgets Jsx

/-- Bit change status for visualization -/
inductive BitChange
  | unchanged : Bool → BitChange  -- value stayed the same
  | set       : BitChange         -- 0 → 1 (green)
  | cleared   : BitChange         -- 1 → 0 (red)
  deriving Inhabited

/-- Compare two bit values and determine change -/
def compareBits (before after : Bool) : BitChange :=
  match before, after with
  | false, true  => .set
  | true,  false => .cleared
  | b,     _     => .unchanged b

/-- CSS for bitop visualization -/
def bitOpStyles : String :=
"
.bitop-container {
  font-family: 'SF Mono', 'Monaco', 'Menlo', monospace;
  font-size: 12px;
  padding: 8px;
}
.bitop-title {
  font-weight: bold;
  margin-bottom: 8px;
  color: #666;
}
.bitop-row {
  display: flex;
  align-items: center;
  margin: 4px 0;
  gap: 8px;
}
.bitop-label {
  min-width: 60px;
  font-weight: 500;
  color: #666;
}
.bitop-grid {
  display: flex;
  gap: 2px;
}
.bitop-cell {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 2px 4px;
  border-radius: 3px;
  min-width: 20px;
  font-size: 11px;
}
.bitop-cell-0 {
  background-color: #e0e0e0;
  color: #666;
}
.bitop-cell-1 {
  background-color: #4caf50;
  color: white;
}
.bitop-cell-set {
  background-color: #2e7d32;
  color: white;
  box-shadow: 0 0 4px #4caf50;
}
.bitop-cell-cleared {
  background-color: #c62828;
  color: white;
  box-shadow: 0 0 4px #ef5350;
}
.bitop-hex {
  font-family: monospace;
  color: #1976d2;
  min-width: 80px;
}
.bitop-op {
  font-size: 16px;
  font-weight: bold;
  color: #333;
  padding: 0 8px;
}
.bitop-arrow {
  font-size: 14px;
  color: #666;
}
"

/-- Render a single bit cell with change highlighting -/
def renderBitOpCell (_index : Nat) (change : BitChange) : Html :=
  let (cls, value) := match change with
    | .unchanged false => ("bitop-cell bitop-cell-0", "0")
    | .unchanged true  => ("bitop-cell bitop-cell-1", "1")
    | .set             => ("bitop-cell bitop-cell-set", "1")
    | .cleared         => ("bitop-cell bitop-cell-cleared", "0")
  Html.element "div" #[attr "class" cls] #[
    Html.element "span" #[] #[.text value]
  ]

/-- Render a row of bits (input or output) -/
def renderBitRow {n : Nat} (label : String) (bv : BitVec n) (changes : Option (List BitChange) := none) : Html :=
  let hexStr := s!"0x{bv.toHex}"
  let cells := (List.range n).reverse.map fun i =>
    match changes with
    | some cs => renderBitOpCell i (cs.getD i (.unchanged false))
    | none =>
      let v := bv.getLsbD i
      let cls := if v then "bitop-cell bitop-cell-1" else "bitop-cell bitop-cell-0"
      Html.element "div" #[attr "class" cls] #[
        Html.element "span" #[] #[.text (if v then "1" else "0")]
      ]
  Html.element "div" #[attr "class" "bitop-row"] #[
    Html.element "span" #[attr "class" "bitop-label"] #[.text label],
    Html.element "span" #[attr "class" "bitop-hex"] #[.text hexStr],
    Html.element "div" #[attr "class" "bitop-grid"] cells.toArray
  ]

/-- Compute bit changes between input and output -/
def computeChanges {n : Nat} (input output : BitVec n) : List BitChange :=
  (List.range n).map fun i =>
    compareBits (input.getLsbD i) (output.getLsbD i)

/-- Visualize a unary bitwise operation (NOT, shifts) -/
def showUnaryOp {n : Nat} (opName : String) (input output : BitVec n) : Html :=
  let changes := computeChanges input output
  Html.element "div" #[attr "class" "bitop-container"] #[
    Html.element "style" #[] #[.text bitOpStyles],
    Html.element "div" #[attr "class" "bitop-title"] #[.text s!"{opName} Operation"],
    renderBitRow "Input:" input none,
    Html.element "div" #[attr "class" "bitop-row"] #[
      Html.element "span" #[attr "class" "bitop-arrow"] #[.text "  ↓"],
      Html.element "span" #[attr "class" "bitop-op"] #[.text opName]
    ],
    renderBitRow "Output:" output (some changes)
  ]

/-- Visualize a binary bitwise operation (AND, OR, XOR) -/
def showBinaryOp {n : Nat} (opName : String) (a b output : BitVec n) : Html :=
  let changesA := computeChanges a output
  let _changesB := computeChanges b output  -- could show B's perspective too
  Html.element "div" #[attr "class" "bitop-container"] #[
    Html.element "style" #[] #[.text bitOpStyles],
    Html.element "div" #[attr "class" "bitop-title"] #[.text s!"{opName} Operation"],
    renderBitRow "A:" a none,
    Html.element "div" #[attr "class" "bitop-row"] #[
      Html.element "span" #[attr "class" "bitop-op"] #[.text opName]
    ],
    renderBitRow "B:" b none,
    Html.element "div" #[attr "class" "bitop-row"] #[
      Html.element "span" #[attr "class" "bitop-arrow"] #[.text "  ↓"]
    ],
    renderBitRow "Result:" output (some changesA)
  ]

/-- Show AND operation with mask highlighting -/
def showAnd {n : Nat} (value mask : BitVec n) : Html :=
  showBinaryOp "AND (&)" value mask (value &&& mask)

/-- Show OR operation -/
def showOr {n : Nat} (a b : BitVec n) : Html :=
  showBinaryOp "OR (|)" a b (a ||| b)

/-- Show XOR operation -/
def showXor {n : Nat} (a b : BitVec n) : Html :=
  showBinaryOp "XOR (^)" a b (a ^^^ b)

/-- Show NOT operation -/
def showNot {n : Nat} (value : BitVec n) : Html :=
  showUnaryOp "NOT (~)" value (~~~value)

/-- Show left shift -/
def showShl {n : Nat} (value : BitVec n) (shift : Nat) : Html :=
  showUnaryOp s!"SHL << {shift}" value (value <<< shift)

/-- Show right shift -/
def showShr {n : Nat} (value : BitVec n) (shift : Nat) : Html :=
  showUnaryOp s!"SHR >> {shift}" value (value >>> shift)

/-! ## Demo: Masking operations -/

-- Example: Clear specific bits using AND with inverted mask
def clearBits : BitVec 8 := 0b11110101
def mask : BitVec 8 := 0b11110000  -- keep upper 4 bits

#html showAnd clearBits mask

-- Example: Set specific bits using OR
def value1 : BitVec 8 := 0b00001010
def setBitsMask : BitVec 8 := 0b11000000  -- set top 2 bits

#html showOr value1 setBitsMask

-- Example: Toggle bits using XOR
def toggleValue : BitVec 8 := 0b10101010
def toggleMask : BitVec 8 := 0b00001111  -- toggle lower 4 bits

#html showXor toggleValue toggleMask

-- Example: Bitwise NOT
#html showNot (0b10101010 : BitVec 8)

-- Example: Shifts
#html showShl (0b00001111 : BitVec 8) 2
#html showShr (0b11110000 : BitVec 8) 3

/-! ## Practical example: Setting and clearing flags -/

/-- Demo: Modifying Linux-style page flags -/
def originalFlags : BitVec 8 := 0b00100100  -- DIRTY | REFERENCED
def flagsToClear : BitVec 8 := 0b11111011  -- Clear DIRTY (bit 2)
def flagsToSet : BitVec 8 := 0b00000001    -- Set LOCKED (bit 0)

-- Step 1: Clear DIRTY flag
#html showBinaryOp "Clear DIRTY" originalFlags flagsToClear (originalFlags &&& flagsToClear)

-- Step 2: Set LOCKED flag
def afterClear : BitVec 8 := originalFlags &&& flagsToClear
#html showBinaryOp "Set LOCKED" afterClear flagsToSet (afterClear ||| flagsToSet)
