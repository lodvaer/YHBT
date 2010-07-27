;; The different kinds of memory there can be.
; Goes in the high AVL-part of the page tables.

MM.STACK  = 52
MM.CODE   = 53
MM.RODATA = 54
MM.RWDATA = 55
MM.TDATA  = 56 ; Thread-local data.
MM.SHM    = 57
MM.FILE   = 58
MM.LIB    = 59

MM.NX     = 63

; vim: ts=8 sw=8 syn=fasm
