import BitFieldVisualizer.DeriveToBitField

/-!
# Example: Using the ToBitField deriving handler

Demonstrates automatic generation of `ToBitField` instances for structures.
-/

open Lean Widget ProofWidgets

/-- Simple status flags -/
structure StatusFlags where
  enabled : Bool
  ready : Bool
  error : Bool
  overflow : Bool
  deriving ToBitField

/-- Verify the instance was generated -/
#check (inferInstance : ToBitField StatusFlags 4)

/-- Create a value and visualize it -/
def myStatus : StatusFlags := {
  enabled := true
  ready := false
  error := true
  overflow := false
}

-- Test that toBitVec works
#eval (ToBitField.toBitVec myStatus).toNat  -- Should be 0b0101 = 5

-- Visualize with auto-generated labels
#html showBits myStatus (some "Status Flags")

/-- Permission flags (like Unix) -/
structure PermFlags where
  read : Bool
  write : Bool
  execute : Bool
  deriving ToBitField

def rwx : PermFlags := { read := true, write := true, execute := true }
def rx : PermFlags := { read := true, write := false, execute := true }

#eval (ToBitField.toBitVec rwx).toNat  -- 0b111 = 7
#eval (ToBitField.toBitVec rx).toNat   -- 0b101 = 5

#html showBits rwx (some "RWX Permissions")
#html showBits rx (some "R-X Permissions")

/-- Hardware register bits -/
structure ControlReg where
  powerOn : Bool
  clockEnabled : Bool
  interruptMask : Bool
  dmaEnabled : Bool
  fifoReset : Bool
  loopback : Bool
  deriving ToBitField

def defaultCtrl : ControlReg := {
  powerOn := true
  clockEnabled := true
  interruptMask := false
  dmaEnabled := false
  fifoReset := false
  loopback := false
}

#html showBits defaultCtrl (some "Control Register")
