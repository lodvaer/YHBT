
; fork :: Int flags | null
; The flags:
KEEP_CODE  =
KEEP_DATA  =
KEEP_STACK =
KEEP_TLS   =
KEEP_FDS   =

; Addrs: 0-7FFF FFFF FFFFh
; Code starts at: 
;  0000 0020 0000h
; Data starts at:
;  0040 0000 0000h
; TLS starts at:
;  0080 0000 0000h
; ??? starts at:
;  00C0 0000 0000h
; Libraries then ???

; vim: ts=8 sw=8 syn=fasm
