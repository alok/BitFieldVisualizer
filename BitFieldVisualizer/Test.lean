import ProofWidgets.Component.HtmlDisplay
import BitFieldVisualizer.Basic

open ProofWidgets Lean

-- Test 1: Simple text
#html Html.text "Test 1: Simple text"

-- Test 2: Element with attribute
#html Html.element "div" #[attr "class" "test"] #[Html.text "Test 2: With class attr"]

-- Test 3: Nested elements
#html Html.element "div" #[] #[
  Html.element "span" #[] #[Html.text "Test 3a"],
  Html.element "span" #[] #[Html.text "Test 3b"]
]

-- Test 4: Style element
#html Html.element "div" #[] #[
  Html.element "style" #[] #[Html.text ".red { color: red; }"],
  Html.element "span" #[attr "class" "red"] #[Html.text "Test 4: Styled"]
]

-- Test 5: List converted to Array (like our widget)
def testItems : List Html := [
  Html.element "span" #[] #[Html.text "Item 1"],
  Html.element "span" #[] #[Html.text "Item 2"]
]

#html Html.element "div" #[] testItems.toArray

-- Test 6: Minimal bitfield (no labels, no legend)
def minimalBitfield : Html :=
  let bits := [true, false, true, false]
  let cells := (List.range 4).map fun i =>
    let v := bits.getD i false
    let cls := if v then "set" else "unset"
    Html.element "span" #[attr "class" cls] #[Html.text (if v then "1" else "0")]
  Html.element "div" #[] cells.toArray

#html minimalBitfield

-- Test 7: The actual widget
#html showBitField (0x5 : BitVec 4) (BitFieldLabels.empty 4) none

-- Test 8: Just the bit cells (no legend, no style)
def testBitCells : Html :=
  let bv : BitVec 4 := 0x5
  let labels := BitFieldLabels.empty 4
  let bits := extractBitInfo bv labels
  let bitCells := bits.map renderBitCell
  Html.element "div" #[] bitCells.toArray

#html testBitCells

-- Test 9: Just the style element
#html Html.element "div" #[] #[
  Html.element "style" #[] #[Html.text bitfieldStyles]
]

-- Test 10: Style + simple content
#html Html.element "div" #[] #[
  Html.element "style" #[] #[Html.text ".test { color: red; }"],
  Html.element "span" #[] #[Html.text "After style"]
]

-- Test 11: Just the legend
def testLegend : Html :=
  let bv : BitVec 4 := 0x5
  let labels := BitFieldLabels.empty 4
  let bits := extractBitInfo bv labels
  renderLegend bits

#html testLegend

-- Test 12: BitCells + Legend (no style)
def testNostyle : Html :=
  let bv : BitVec 4 := 0x5
  let labels := BitFieldLabels.empty 4
  let bits := extractBitInfo bv labels
  let bitCells := bits.map renderBitCell
  Html.element "div" #[] #[
    Html.element "div" #[] bitCells.toArray,
    renderLegend bits
  ]

#html testNostyle
