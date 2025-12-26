# BitFieldVisualizer

A Lean 4 infoview widget for visualizing labeled bitfields, inspired by Linux kernel page flags and hardware register definitions.

![Lean](https://img.shields.io/badge/Lean-4.26.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Visual bitfield display** - Color-coded bits (green=set, gray=unset) with index labels
- **Custom labels** - Name individual bits like `LOCKED`, `DIRTY`, `REFERENCED`
- **Descriptions** - Hover tooltips for detailed bit documentation
- **Bitwise operations** - Visualize AND, OR, XOR, NOT, shifts with change highlighting
- **Composable API** - Type class, builder pattern, and combinators for custom visualizations
- **Deriving handler** - Auto-generate `ToBitField` instances from structures

## Installation

Add to your `lakefile.toml`:

```toml
[[require]]
name = "BitFieldVisualizer"
git = "https://github.com/alok/BitFieldVisualizer"
rev = "v0.1.0"
```

## Quick Start

```lean
import BitFieldVisualizer

-- Simple visualization
#html showBitField (0x45 : BitVec 8) (BitFieldLabels.empty 8)

-- With labels
def pageFlags : BitFieldLabels 8 := BitFieldLabels.fromList [
  (0, "LOCKED"), (1, "ERROR"), (2, "REFERENCED"),
  (3, "UPTODATE"), (4, "DIRTY"), (5, "LRU")
]
#html showBitField (0x15 : BitVec 8) pageFlags (some "Page Flags")

-- With descriptions (hover to see)
def flagsWithDocs : BitFieldLabels 8 := BitFieldLabels.fromListWithDesc [
  (0, "LOCKED", "Page is locked for I/O"),
  (1, "ERROR", "I/O error occurred"),
  (2, "REFERENCED", "Page was recently accessed")
]
#html showBitField (0x05 : BitVec 8) flagsWithDocs
```

## Deriving Handler

Auto-generate instances for structures with Bool fields:

```lean
import BitFieldVisualizer.DeriveToBitField

structure StatusFlags where
  enabled : Bool
  ready : Bool
  error : Bool
  overflow : Bool
  deriving ToBitField

def myStatus : StatusFlags := { enabled := true, ready := false, error := true, overflow := false }
#html showBits myStatus (some "Status Flags")
```

## Bitwise Operations

Visualize operations with before/after highlighting:

```lean
import BitFieldVisualizer.BitOps

-- AND with mask (red = cleared bits)
#html showAnd (0b11110101 : BitVec 8) (0b11110000 : BitVec 8)

-- OR to set bits (green = newly set)
#html showOr (0b00001010 : BitVec 8) (0b11000000 : BitVec 8)

-- XOR to toggle
#html showXor (0b10101010 : BitVec 8) (0b00001111 : BitVec 8)

-- Shifts
#html showShl (0b00001111 : BitVec 8) 2
#html showShr (0b11110000 : BitVec 8) 3
```

## Composable API

```lean
import BitFieldVisualizer.Composable

-- Builder pattern
#html BitFieldBuilder.new (0xAB : BitVec 8)
  |>.withTitle "My Register"
  |>.noLegend
  |>.render

-- Combinators
#html vstack [
  labeled "Before" (showBits (0x0F : BitVec 8)),
  labeled "After"  (showBits (0xF0 : BitVec 8))
]

#html hstack [
  labeled "Input"  (showBits (0xAA : BitVec 8)),
  labeled "Mask"   (showBits (0x0F : BitVec 8)),
  labeled "Result" (showBits (0x0A : BitVec 8))
]

-- With property verification
#html withProperty (0x04 : BitVec 8) "is power of 2" true
```

## API Reference

### Core Functions

- `showBitField : BitVec n → BitFieldLabels n → Option String → Html`
- `showBits : [ToBitField α n] → α → Option String → Html`

### Labels

- `BitFieldLabels.empty : (n : Nat) → BitFieldLabels n`
- `BitFieldLabels.fromList : List (Nat × String) → BitFieldLabels n`
- `BitFieldLabels.fromListWithDesc : List (Nat × String × String) → BitFieldLabels n`

### Operations

- `showAnd`, `showOr`, `showXor`, `showNot`, `showShl`, `showShr`

### Combinators

- `vstack`, `hstack`, `labeled`, `withProperty`
- `BitFieldBuilder.new`, `.withTitle`, `.withLabels`, `.noLegend`, `.render`

## Requirements

- Lean 4.26.0+
- ProofWidgets4

## License

Apache-2.0
