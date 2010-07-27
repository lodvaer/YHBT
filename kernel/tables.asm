;; Various system tales and such.

append TO_INIT_64, tables.init
macro tables.init
{
	; Initializing the TSS is currently done in init/main.asm
}
; 1: 32bit code
; 2: 64bit kernel code
; 3: 32/64bit data
; 4: 64bit lusermode code
; 5: 64bit lusermode data
SEL_NULL     = 0
SEL_CODE     = 1 shl 3
SEL_LONG     = 2 shl 3
SEL_DATA     = 3 shl 3 ; Data MUST follow long.

SEL_USR_32b  = (4 shl 3) or 3 ; USR stuff MUST be in this order.
SEL_USR_DATA = (5 shl 3) or 3
SEL_USR_LONG = (6 shl 3) or 3

SEL_TSS      = 8 shl 3

align 8
IDTR:
	dw 256*16-1
	dq IDENT_MAP
align 8

GDT:
	dw 0Ah*8-1
.loc:	dd .rGDT
	dd 0
align 8
.rGDT:
.0:	dq 0 ; Unused

.1:	dq 0000000011011111100110100000000000000000000000001111111111111111b
.2:	dq 0000000000100000100110000000000000000000000000000000000000000000b
;	   -ignored-||-----||/|||------------------------------------------
;		    ||     || ||`->Conforming
;		    |`Long || |`->Code/Data
;		    |	   || `->User
;		    |	   |`->CPL 0-3
;		    |	   `->Present
;		    `->If long, must be zero (default operand size)
.3:	dq 0000000011011111100100100000000000000000000000001111111111111111b
; Usermode:
;.4:	dq 0 ; 32-bit CPL
.4:	dq 0
.5:	dq 0000000000110000111100100000000000000000000000000000000000000000b
.6:	dq 0000000000110000111111000000000000000000000000000000000000000000b
.7:	dq 0 ; Not really needed padding.
.8:	system_segment_desc (TSS + IDENT_MAP), 103, 8900h	; Takes 16 bytes
.10:

TSS:
TSS.ign1:	dd 0 ; Ignored
TSS.rsp0:	dq 0 ; RSP for CPL=0
TSS.rsp1:	dq 0 ; RSP for CPL=1
TSS.rsp2:	dq 0 ; RSP for CPL=2
TSS.ign2:	dq 0 ; Ignored
TSS.ist1:	dq 0
TSS.ist2:	dq 0
TSS.ist3:	dq 0
TSS.ist4:	dq 0 ; Interrupt stack tables.
TSS.ist5:	dq 0
TSS.ist6:	dq 0
TSS.ist7:	dq 0
TSS.ign3:	dq 0 ; Ignored
TSS.ign4:	dw 0 ; Ignored
TSS.iobase:	dw 0 ; IO bitmap offset.


; vim: ts=8 sw=8 syn=fasm
