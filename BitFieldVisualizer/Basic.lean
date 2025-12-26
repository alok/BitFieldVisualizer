import ProofWidgets.Component.HtmlDisplay
import ProofWidgets.Component.Panel.Basic
import Lean.Data.Json

open Lean Widget ProofWidgets

/-!
# BitField Visualizer Widget

An infoview widget for visualizing labeled bitfields, inspired by Linux kernel
page flags and register definitions.

## Usage

```lean
-- Define labels for each bit position
def pageFlags : BitFieldLabels 27 := BitFieldLabels.fromList [
  (0, "LOCKED"), (1, "ERROR"), (2, "REFERENCED"), ...
]

-- Show the widget
#html showBitField (0x45 : BitVec 27) pageFlags
```
-/

/-- Labels for bit positions in a bitfield of width `n`. -/
structure BitFieldLabels (n : Nat) where
  /-- Map from bit position to label string -/
  labels : Fin n → Option String
  /-- Optional description for each bit -/
  descriptions : Fin n → Option String := fun _ => none

namespace BitFieldLabels

/-- Create labels from a list of (position, label) pairs. -/
def fromList {n : Nat} (pairs : List (Nat × String)) : BitFieldLabels n :=
  { labels := fun i =>
      pairs.find? (fun (pos, _) => pos == i.val) |>.map Prod.snd
  }

/-- Create labels with descriptions from a list of (position, label, description) triples. -/
def fromListWithDesc {n : Nat} (triples : List (Nat × String × String)) : BitFieldLabels n :=
  { labels := fun i =>
      triples.find? (fun (pos, _, _) => pos == i.val) |>.map (·.2.1)
    descriptions := fun i =>
      triples.find? (fun (pos, _, _) => pos == i.val) |>.map (·.2.2)
  }

/-- Empty labels (just show bit indices). -/
def empty (n : Nat) : BitFieldLabels n :=
  { labels := fun _ => none }

end BitFieldLabels

/-- Information about a single bit for rendering. -/
structure BitInfo where
  index : Nat
  value : Bool
  label : Option String
  description : Option String
  deriving Inhabited

/-- Extract bit information from a BitVec with labels. -/
def extractBitInfo {n : Nat} (bv : BitVec n) (labels : BitFieldLabels n) : List BitInfo :=
  List.range n |>.map fun i =>
    if h : i < n then
      let fin_i : Fin n := ⟨i, h⟩
      { index := i
        value := bv.getLsbD i
        label := labels.labels fin_i
        description := labels.descriptions fin_i
      }
    else
      { index := i, value := false, label := none, description := none }

/-- Generate CSS styles for the bitfield widget. -/
def bitfieldStyles : String :=
"
.bitfield-container {
  font-family: 'SF Mono', 'Monaco', 'Menlo', monospace;
  font-size: 12px;
  padding: 8px;
}
.bitfield-title {
  font-weight: bold;
  margin-bottom: 8px;
  color: #666;
}
.bitfield-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 2px;
  margin-bottom: 12px;
}
.bit-cell {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 4px 6px;
  border-radius: 4px;
  min-width: 28px;
  cursor: default;
}
.bit-cell-set {
  background-color: #4caf50;
  color: white;
}
.bit-cell-unset {
  background-color: #e0e0e0;
  color: #666;
}
.bit-index {
  font-size: 9px;
  color: inherit;
  opacity: 0.7;
}
.bit-value {
  font-weight: bold;
  font-size: 14px;
}
.bit-label {
  font-size: 8px;
  max-width: 60px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.legend {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid #e0e0e0;
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 2px 0;
  font-size: 11px;
}
.legend-bit {
  font-weight: bold;
  min-width: 20px;
  color: #4caf50;
}
.legend-label {
  color: #333;
  font-weight: 500;
}
.legend-desc {
  color: #666;
  font-style: italic;
}
.hex-display {
  font-family: monospace;
  color: #1976d2;
  margin-top: 4px;
}
"

/-- Helper to create string attribute for Html.element -/
def attr (name value : String) : String × Json := (name, Json.str value)

/-- Convert a natural number to a binary string. -/
def Nat.toBinString (n : Nat) : String :=
  if n == 0 then "0"
  else go n ""
where
  go : Nat → String → String
  | 0, acc => acc
  | n+1, acc => go ((n+1) / 2) (toString ((n+1) % 2) ++ acc)
  termination_by n => n

/-- Convert a natural number to a binary string, padded to given width. -/
def Nat.toBinStringPadded (n width : Nat) : String :=
  let s := n.toBinString
  let padding := width - s.length
  String.ofList (List.replicate padding '0') ++ s

/-- Render a single bit cell as HTML. -/
def renderBitCell (info : BitInfo) : Html :=
  let cellClass := if info.value then "bit-cell bit-cell-set" else "bit-cell bit-cell-unset"
  let valueStr := if info.value then "1" else "0"
  let labelStr := info.label.getD s!"b{info.index}"
  let titleStr := match info.description with
    | some d => s!"Bit {info.index}: {labelStr} - {d}"
    | none => s!"Bit {info.index}: {labelStr}"
  Html.element "div" #[attr "class" cellClass, attr "title" titleStr] #[
    Html.element "span" #[attr "class" "bit-index"] #[.text (toString info.index)],
    Html.element "span" #[attr "class" "bit-value"] #[.text valueStr],
    Html.element "span" #[attr "class" "bit-label"] #[.text labelStr]
  ]

/-- Render legend for set bits. -/
def renderLegend (bits : List BitInfo) : Html :=
  let setBits := bits.filter (·.value)
  if setBits.isEmpty then
    Html.element "div" #[attr "class" "legend"] #[
      Html.element "em" #[] #[.text "No bits set"]
    ]
  else
    let items := setBits.map fun info =>
      let labelStr := info.label.getD s!"bit_{info.index}"
      let children : Array Html := match info.description with
        | some d => #[
            Html.element "span" #[attr "class" "legend-bit"] #[.text s!"[{info.index}]"],
            Html.element "span" #[attr "class" "legend-label"] #[.text labelStr],
            Html.element "span" #[attr "class" "legend-desc"] #[.text s!"({d})"]
          ]
        | none => #[
            Html.element "span" #[attr "class" "legend-bit"] #[.text s!"[{info.index}]"],
            Html.element "span" #[attr "class" "legend-label"] #[.text labelStr]
          ]
      Html.element "div" #[attr "class" "legend-item"] children
    Html.element "div" #[attr "class" "legend"] #[
      Html.element "div" #[attr "style" "font-weight: bold; margin-bottom: 4px"] #[.text "Set bits:"],
      Html.element "div" #[] items.toArray
    ]

/-- Main widget HTML generation. -/
def renderBitFieldHtml {n : Nat} (bv : BitVec n) (labels : BitFieldLabels n)
    (title : Option String := none) : Html :=
  let bits := extractBitInfo bv labels
  -- Show bits from MSB to LSB (reversed order)
  let bitsReversed := bits.reverse
  let bitCells := bitsReversed.map renderBitCell
  let hexStr := s!"0x{bv.toHex}"
  let binStr := s!"0b{bv.toNat.toBinStringPadded n}"
  let titleStr := title.getD s!"BitVec {n}"
  Html.element "div" #[attr "class" "bitfield-container"] #[
    Html.element "style" #[] #[.text bitfieldStyles],
    Html.element "div" #[attr "class" "bitfield-title"] #[.text titleStr],
    Html.element "div" #[attr "class" "hex-display"] #[.text s!"{hexStr} = {binStr}"],
    Html.element "div" #[attr "class" "bitfield-grid"] bitCells.toArray,
    renderLegend bits
  ]

/-- Widget props for the bitfield visualizer. -/
structure BitFieldWidgetProps where
  /-- Number of bits -/
  width : Nat
  /-- The value as a natural number -/
  value : Nat
  /-- Labels as (index, label, description?) triples -/
  labelData : Array (Nat × String × Option String)
  /-- Optional title -/
  title : Option String := none
  deriving Server.RpcEncodable

/-- The main bitfield widget module using React. -/
@[widget_module]
def BitFieldWidget : Widget.Module where
  javascript := "
import * as React from 'react';
const e = React.createElement;

const styles = `
.bitfield-container {
  font-family: 'SF Mono', 'Monaco', 'Menlo', monospace;
  font-size: 12px;
  padding: 8px;
}
.bitfield-title {
  font-weight: bold;
  margin-bottom: 8px;
  color: #666;
}
.bitfield-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 2px;
  margin-bottom: 12px;
}
.bit-cell {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 4px 6px;
  border-radius: 4px;
  min-width: 28px;
  cursor: default;
  transition: transform 0.1s;
}
.bit-cell:hover {
  transform: scale(1.1);
}
.bit-cell-set {
  background-color: #4caf50;
  color: white;
}
.bit-cell-unset {
  background-color: #e0e0e0;
  color: #666;
}
.bit-index {
  font-size: 9px;
  opacity: 0.7;
}
.bit-value {
  font-weight: bold;
  font-size: 14px;
}
.bit-label {
  font-size: 8px;
  max-width: 60px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 2px 0;
  font-size: 11px;
}
.legend-bit {
  font-weight: bold;
  min-width: 20px;
  color: #4caf50;
}
.legend-label {
  color: #333;
  font-weight: 500;
}
.legend-desc {
  color: #666;
  font-style: italic;
}
.hex-display {
  font-family: monospace;
  color: #1976d2;
  margin-bottom: 8px;
}
`;

function BitCell({ index, value, label, description }) {
  const className = 'bit-cell ' + (value ? 'bit-cell-set' : 'bit-cell-unset');
  const title = description
    ? 'Bit ' + index + ': ' + (label || 'b' + index) + ' - ' + description
    : 'Bit ' + index + ': ' + (label || 'b' + index);
  return e('div', { className, title },
    e('span', { className: 'bit-index' }, index),
    e('span', { className: 'bit-value' }, value ? '1' : '0'),
    e('span', { className: 'bit-label' }, label || 'b' + index)
  );
}

function Legend({ bits }) {
  const setBits = bits.filter(b => b.value);
  if (setBits.length === 0) {
    return e('div', { style: { marginTop: '8px', fontStyle: 'italic' } }, 'No bits set');
  }
  return e('div', { style: { marginTop: '8px', paddingTop: '8px', borderTop: '1px solid #e0e0e0' } },
    e('div', { style: { fontWeight: 'bold', marginBottom: '4px' } }, 'Set bits:'),
    ...setBits.map(info =>
      e('div', { className: 'legend-item', key: info.index },
        e('span', { className: 'legend-bit' }, '[' + info.index + ']'),
        e('span', { className: 'legend-label' }, info.label || 'bit_' + info.index),
        info.description && e('span', { className: 'legend-desc' }, '(' + info.description + ')')
      )
    )
  );
}

export default function BitFieldWidget(props) {
  const { width, value, labelData, title } = props;

  // Build label map
  const labelMap = {};
  const descMap = {};
  for (const [idx, lbl, desc] of labelData || []) {
    labelMap[idx] = lbl;
    if (desc) descMap[idx] = desc;
  }

  // Extract bits
  const bits = [];
  for (let i = 0; i < width; i++) {
    bits.push({
      index: i,
      value: (value & (1 << i)) !== 0,
      label: labelMap[i],
      description: descMap[i]
    });
  }

  // Display MSB to LSB
  const bitsReversed = [...bits].reverse();

  // Format hex and binary
  const hexStr = '0x' + value.toString(16).toUpperCase();
  const binStr = '0b' + value.toString(2).padStart(width, '0');

  return e('div', { className: 'bitfield-container' },
    e('style', null, styles),
    e('div', { className: 'bitfield-title' }, title || ('BitVec ' + width)),
    e('div', { className: 'hex-display' }, hexStr + ' = ' + binStr),
    e('div', { className: 'bitfield-grid' },
      ...bitsReversed.map(info =>
        e(BitCell, { key: info.index, ...info })
      )
    ),
    e(Legend, { bits })
  );
}
"

/-- Show a bitfield widget in the infoview. -/
def showBitField {n : Nat} (bv : BitVec n) (labels : BitFieldLabels n)
    (title : Option String := none) : Html :=
  renderBitFieldHtml bv labels title
