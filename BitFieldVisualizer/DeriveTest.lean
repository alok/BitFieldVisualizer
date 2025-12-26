import BitFieldVisualizer.DeriveToBitField
import Plausible

/-!
# Property-based tests for ToBitField deriving handler

Uses Plausible to verify that the derived instances behave correctly.
-/

-- Simple 4-bit flags
structure Flags4 where
  a : Bool
  b : Bool
  c : Bool
  d : Bool
  deriving ToBitField, Repr, DecidableEq

-- 8-bit register
structure Reg8 where
  bit0 : Bool
  bit1 : Bool
  bit2 : Bool
  bit3 : Bool
  bit4 : Bool
  bit5 : Bool
  bit6 : Bool
  bit7 : Bool
  deriving ToBitField, Repr, DecidableEq

-- Arbitrary and SampleableExt instances for our structures
deriving instance Plausible.Arbitrary for Flags4
deriving instance Plausible.Arbitrary for Reg8

-- Shrinkable instances (trivial for Bool-only structs)
instance : Plausible.Shrinkable Flags4 where
  shrink _ := []
instance : Plausible.Shrinkable Reg8 where
  shrink _ := []

instance : Plausible.SampleableExt Flags4 := Plausible.SampleableExt.selfContained
instance : Plausible.SampleableExt Reg8 := Plausible.SampleableExt.selfContained

-- Helper to get bit at position from BitVec
def getBit (bv : BitVec n) (i : Nat) : Bool := bv.getLsbD i

/-! ## Property Tests -/

-- Property: First field maps to bit 0
#eval Plausible.Testable.check (∀ (f : Flags4), getBit (ToBitField.toBitVec f) 0 = f.a)

-- Property: Second field maps to bit 1
#eval Plausible.Testable.check (∀ (f : Flags4), getBit (ToBitField.toBitVec f) 1 = f.b)

-- Property: Third field maps to bit 2
#eval Plausible.Testable.check (∀ (f : Flags4), getBit (ToBitField.toBitVec f) 2 = f.c)

-- Property: Fourth field maps to bit 3
#eval Plausible.Testable.check (∀ (f : Flags4), getBit (ToBitField.toBitVec f) 3 = f.d)

-- Property: All false produces zero
#eval Plausible.Testable.check ((ToBitField.toBitVec (⟨false, false, false, false⟩ : Flags4)).toNat = 0)

-- Property: All true produces 2^n - 1
#eval Plausible.Testable.check ((ToBitField.toBitVec (⟨true, true, true, true⟩ : Flags4)).toNat = 15)

-- Property: Only first bit set produces 1
#eval Plausible.Testable.check ((ToBitField.toBitVec (⟨true, false, false, false⟩ : Flags4)).toNat = 1)

-- Property: Only last bit set produces 2^(n-1)
#eval Plausible.Testable.check ((ToBitField.toBitVec (⟨false, false, false, true⟩ : Flags4)).toNat = 8)

-- Property: Bit positions are independent
#eval Plausible.Testable.check (∀ (f : Flags4),
  let bv := ToBitField.toBitVec f
  (getBit bv 0, getBit bv 1, getBit bv 2, getBit bv 3) = (f.a, f.b, f.c, f.d))

-- Property: Value is bounded by 2^n
#eval Plausible.Testable.check (∀ (f : Flags4), (ToBitField.toBitVec f).toNat < 16)

-- Property: 8-bit register - bits map correctly (test each bit)
#eval Plausible.Testable.check (∀ (r : Reg8), getBit (ToBitField.toBitVec r) 0 = r.bit0)
#eval Plausible.Testable.check (∀ (r : Reg8), getBit (ToBitField.toBitVec r) 1 = r.bit1)
#eval Plausible.Testable.check (∀ (r : Reg8), getBit (ToBitField.toBitVec r) 7 = r.bit7)

-- Property: 8-bit all zeros
#eval Plausible.Testable.check ((ToBitField.toBitVec (⟨false, false, false, false, false, false, false, false⟩ : Reg8)).toNat = 0)

-- Property: 8-bit all ones
#eval Plausible.Testable.check ((ToBitField.toBitVec (⟨true, true, true, true, true, true, true, true⟩ : Reg8)).toNat = 255)

/-! ## Verify labels are generated correctly -/

#check (ToBitField.labels (α := Flags4))
#check (ToBitField.labels (α := Reg8))

-- Verify the instance exists and has correct width
example : ToBitField Flags4 4 := inferInstance
example : ToBitField Reg8 8 := inferInstance

/-! ## Visual tests (check in infoview) -/

open Lean Widget ProofWidgets in
#html showBits (⟨true, false, true, false⟩ : Flags4) (some "Flags4 Test")

open Lean Widget ProofWidgets in
#html showBits (⟨true, true, false, false, true, true, false, false⟩ : Reg8) (some "Reg8 Test: 0xCC")
