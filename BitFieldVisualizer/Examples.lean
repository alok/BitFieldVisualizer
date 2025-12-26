import BitFieldVisualizer.Basic

/-!
# Linux Kernel Bitfield Examples

Translated from Linux kernel header files to demonstrate the BitField widget.

## Sources
- `include/uapi/linux/kernel-page-flags.h` - Page flags
- `include/linux/fs.h` - File mode flags
- `include/uapi/linux/stat.h` - Stat mode bits
-/

namespace LinuxKernel

/-!
## Page Flags (KPF_*)

From `include/uapi/linux/kernel-page-flags.h`.
These flags describe the state of physical memory pages.
-/

/-- Linux kernel page flags with descriptions. -/
def pageFlags : BitFieldLabels 27 :=
  BitFieldLabels.fromListWithDesc [
    (0,  "LOCKED",       "Page is locked in memory"),
    (1,  "ERROR",        "Page has I/O error (unused)"),
    (2,  "REFERENCED",   "Page has been referenced recently"),
    (3,  "UPTODATE",     "Page data is current/valid"),
    (4,  "DIRTY",        "Page has been modified"),
    (5,  "LRU",          "Page is on LRU list"),
    (6,  "ACTIVE",       "Page is on active LRU"),
    (7,  "SLAB",         "Page is slab memory"),
    (8,  "WRITEBACK",    "Page is under writeback I/O"),
    (9,  "RECLAIM",      "Page will be reclaimed soon"),
    (10, "BUDDY",        "Buddy allocator free page"),
    (11, "MMAP",         "Page is memory-mapped"),
    (12, "ANON",         "Anonymous memory (no file)"),
    (13, "SWAPCACHE",    "Page is in swap cache"),
    (14, "SWAPBACKED",   "Page is swap-backed"),
    (15, "COMPOUND_HEAD", "Head of compound page"),
    (16, "COMPOUND_TAIL", "Tail of compound page"),
    (17, "HUGE",         "Huge page"),
    (18, "UNEVICTABLE",  "Page cannot be evicted"),
    (19, "HWPOISON",     "Hardware memory error"),
    (20, "NOPAGE",       "Page doesn't exist"),
    (21, "KSM",          "Kernel same-page merging"),
    (22, "THP",          "Transparent huge page"),
    (23, "OFFLINE",      "Page is offline"),
    (24, "ZERO_PAGE",    "Zero/empty page"),
    (25, "IDLE",         "Page is idle"),
    (26, "PGTABLE",      "Page table page")
  ]

/-- Example: A dirty, referenced page on LRU -/
def examplePageFlags1 : BitVec 27 :=
  (1 <<< 2) ||| (1 <<< 4) ||| (1 <<< 5)  -- REFERENCED | DIRTY | LRU

/-- Example: Active anonymous page -/
def examplePageFlags2 : BitVec 27 :=
  (1 <<< 5) ||| (1 <<< 6) ||| (1 <<< 12)  -- LRU | ACTIVE | ANON

#html showBitField examplePageFlags1 pageFlags (some "Page Flags: Dirty Referenced Page")
#html showBitField examplePageFlags2 pageFlags (some "Page Flags: Active Anonymous")

/-!
## File Permission Flags (S_I*)

From `include/uapi/linux/stat.h`.
Traditional Unix file permission bits.
-/

/-- Unix file permission mode bits. -/
def fileMode : BitFieldLabels 12 :=
  BitFieldLabels.fromListWithDesc [
    (0,  "S_IXOTH", "Execute by others"),
    (1,  "S_IWOTH", "Write by others"),
    (2,  "S_IROTH", "Read by others"),
    (3,  "S_IXGRP", "Execute by group"),
    (4,  "S_IWGRP", "Write by group"),
    (5,  "S_IRGRP", "Read by group"),
    (6,  "S_IXUSR", "Execute by owner"),
    (7,  "S_IWUSR", "Write by owner"),
    (8,  "S_IRUSR", "Read by owner"),
    (9,  "S_ISVTX", "Sticky bit"),
    (10, "S_ISGID", "Set-group-ID"),
    (11, "S_ISUID", "Set-user-ID")
  ]

/-- Example: rwxr-xr-x (0755) -/
def mode755 : BitVec 12 := 0o755

/-- Example: rw-r--r-- (0644) -/
def mode644 : BitVec 12 := 0o644

/-- Example: rwsr-xr-x (4755) - setuid executable -/
def mode4755 : BitVec 12 := 0o4755

#html showBitField mode755 fileMode (some "Mode 0755: rwxr-xr-x")
#html showBitField mode644 fileMode (some "Mode 0644: rw-r--r--")
#html showBitField mode4755 fileMode (some "Mode 4755: rwsr-xr-x (setuid)")

/-!
## Open Flags (O_*)

From `include/uapi/asm-generic/fcntl.h`.
Flags for the open() system call.
-/

/-- File open flags. -/
def openFlags : BitFieldLabels 20 :=
  BitFieldLabels.fromListWithDesc [
    (0,  "O_WRONLY",  "Write only"),
    (1,  "O_RDWR",    "Read and write"),
    (6,  "O_CREAT",   "Create if not exists"),
    (7,  "O_EXCL",    "Fail if exists"),
    (8,  "O_NOCTTY",  "Don't assign ctty"),
    (9,  "O_TRUNC",   "Truncate to zero"),
    (10, "O_APPEND",  "Append mode"),
    (11, "O_NONBLOCK", "Non-blocking I/O"),
    (12, "O_DSYNC",   "Sync data writes"),
    (14, "O_ASYNC",   "Signal-driven I/O"),
    (15, "O_DIRECT",  "Direct I/O"),
    (16, "O_LARGEFILE", "Large file support"),
    (17, "O_DIRECTORY", "Must be directory"),
    (18, "O_NOFOLLOW", "Don't follow symlinks"),
    (19, "O_CLOEXEC", "Close on exec")
  ]

/-- Example: O_RDWR | O_CREAT | O_TRUNC (typical for new file) -/
def openFlagsCreate : BitVec 20 :=
  (1 <<< 1) ||| (1 <<< 6) ||| (1 <<< 9)  -- O_RDWR | O_CREAT | O_TRUNC

/-- Example: O_WRONLY | O_APPEND | O_CREAT (log file) -/
def openFlagsAppend : BitVec 20 :=
  (1 <<< 0) ||| (1 <<< 10) ||| (1 <<< 6)  -- O_WRONLY | O_APPEND | O_CREAT

#html showBitField openFlagsCreate openFlags (some "Open: Create/Truncate File")
#html showBitField openFlagsAppend openFlags (some "Open: Append Log File")

/-!
## TCP Socket Flags

From `include/uapi/linux/tcp.h` and related headers.
-/

/-- TCP socket state flags. -/
def tcpFlags : BitFieldLabels 8 :=
  BitFieldLabels.fromListWithDesc [
    (0, "FIN", "No more data from sender"),
    (1, "SYN", "Synchronize sequence numbers"),
    (2, "RST", "Reset the connection"),
    (3, "PSH", "Push function"),
    (4, "ACK", "Acknowledgment field significant"),
    (5, "URG", "Urgent pointer field significant"),
    (6, "ECE", "ECN-Echo"),
    (7, "CWR", "Congestion Window Reduced")
  ]

/-- Example: SYN-ACK packet -/
def synAck : BitVec 8 := (1 <<< 1) ||| (1 <<< 4)

/-- Example: FIN-ACK packet -/
def finAck : BitVec 8 := (1 <<< 0) ||| (1 <<< 4)

#html showBitField synAck tcpFlags (some "TCP: SYN-ACK")
#html showBitField finAck tcpFlags (some "TCP: FIN-ACK")

end LinuxKernel

/-!
## Hardware Register Examples

Common patterns from device drivers.
-/

namespace HardwareRegs

/-- Example: SPI control register. -/
def spiControl : BitFieldLabels 16 :=
  BitFieldLabels.fromListWithDesc [
    (0,  "CPHA",    "Clock phase"),
    (1,  "CPOL",    "Clock polarity"),
    (2,  "MSTR",    "Master mode select"),
    (3,  "BR0",     "Baud rate bit 0"),
    (4,  "BR1",     "Baud rate bit 1"),
    (5,  "BR2",     "Baud rate bit 2"),
    (6,  "SPE",     "SPI enable"),
    (7,  "LSBFIRST", "LSB first"),
    (8,  "SSI",     "Internal slave select"),
    (9,  "SSM",     "Software slave mgmt"),
    (10, "RXONLY",  "Receive only"),
    (11, "CRCL",    "CRC length"),
    (12, "CRCNEXT", "Transmit CRC next"),
    (13, "CRCEN",   "CRC enable"),
    (14, "BIDIOE",  "Bidir output enable"),
    (15, "BIDIMODE", "Bidirectional mode")
  ]

/-- Example: SPI master mode, enabled, 8-bit, mode 0 -/
def spiConfig1 : BitVec 16 := 0b0000000001000100  -- MSTR | SPE

#html showBitField spiConfig1 spiControl (some "SPI CR1: Master Mode Enabled")

/-- Example: GPIO configuration register. -/
def gpioMode : BitFieldLabels 8 :=
  BitFieldLabels.fromListWithDesc [
    (0, "MODE0",  "Mode bit 0"),
    (1, "MODE1",  "Mode bit 1"),
    (2, "OTYPE",  "Output type"),
    (3, "OSPEED0", "Speed bit 0"),
    (4, "OSPEED1", "Speed bit 1"),
    (5, "PUPD0",  "Pull-up/down bit 0"),
    (6, "PUPD1",  "Pull-up/down bit 1"),
    (7, "LOCK",   "Pin locked")
  ]

/-- Example: Output, push-pull, high speed, pull-up -/
def gpioOutputConfig : BitVec 8 := 0b00101001

#html showBitField gpioOutputConfig gpioMode (some "GPIO: Output Push-Pull High-Speed")

end HardwareRegs

/-!
## Custom Bitfield Example

Showing how to create your own labeled bitfield.
-/

/-- Define a custom 8-bit status register. -/
def myStatusReg : BitFieldLabels 8 :=
  BitFieldLabels.fromList [
    (0, "READY"),
    (1, "BUSY"),
    (2, "ERROR"),
    (3, "OVERFLOW"),
    (4, "UNDERFLOW"),
    (5, "TIMEOUT"),
    (6, "IRQ_PENDING"),
    (7, "ENABLED")
  ]

/-- Example status: ready with interrupt pending -/
def status1 : BitVec 8 := 0b01000001

/-- Example status: error with overflow -/
def status2 : BitVec 8 := 0b00001100

#html showBitField status1 myStatusReg (some "Status: Ready + IRQ Pending")
#html showBitField status2 myStatusReg (some "Status: Error + Overflow")

/-!
## Simple Usage

For quick visualization without defining labels:
-/

#html showBitField (0xDEAD : BitVec 16) (BitFieldLabels.empty 16) (some "Raw BitVec 0xDEAD")
#html showBitField (0b10101010 : BitVec 8) (BitFieldLabels.empty 8) (some "Alternating Pattern")
