;REX-prefixes
REX.W equ db 48h
REX.R equ db 44h
REX.X equ db 42h
REX.B equ db 41h
; Make combinations when needed.

;CR0:
CR0.PE equ 0  ; Protection enabled
CR0.MP equ 1  ; Monitor Coprocessor
CR0.EM equ 2  ; Emulation
CR0.TS equ 3  ; Task Switched
CR0.ET equ 4  ; Extension Type
CR0.NE equ 5  ; Numeric Error
;        6-15 : Reserved
CR0.WP equ 16 ; Write Protect
;          17 : Reserved
CR0.AM equ 18 ; Alignment Mask
;       19-28 : Reserved
CR0.NW equ 29 ; Not Writethrough
CR0.CD equ 30 ; Cache disable
CR0.PG equ 31 ; Paging
;       32-63 : Reserved

;CR3:
;         0-2 : Reserved
CR3.PWT equ 3 ; Page-Level Writethrough
CR3.PCD equ 4 ; Page-Level Cache Disable

;CR4:
CR4.VME equ 0  ; Virtual 8086 Mode Extensions
CR4.PVI equ 1  ; Protected Mode Extensions
CR4.TSD equ 2  ; Time Stamp disable
CR4.DE  equ 3  ; Debugging Extensions
CR4.PSE equ 4  ; Page Size Extension
CR4.PAE equ 5  ; Physical Address Extension
CR4.MCE equ 6  ; Machine Check Enable
CR4.PGE equ 7  ; Page-Global Enable
CR4.PCE equ 8  ; Performance-Monitoring counter Enable
CR4.OSF equ 9  ; OS FXSAVE/FXRSTOR Support
CR4.OSX equ 10 ; OS Unmasked Exception Support
;        11-63 : Reserved, Must Be Zero

EFER       equ 0C0000080h ; Addr.
EFER.SCE   equ 0  ; System Call Extensions
;            1-7  : Reserved
EFER.LME   equ 8  ; Long Mode Enable
;              9  : Reserved, MBZ
EFER.LMA   equ 10 ; Long Mode Active
EFER.NXE   equ 11 ; No-Execute Enable
EFER.SVME  equ 12 ; Secure Virtual Machine Enable
;              13 : Reserved, MBZ
EFER.FFXSR equ 14 ; Fast FXSAVE/FXRSTOR
;           15-63 ; Reserved, MBZ

STAR   equ 0C0000081h
LSTAR  equ 0C0000082h
CSTAR  equ 0C0000083h
SFMASK equ 0C0000084h

PIC1.CMD  equ 20h
PIC1.DATA equ 21h
PIC2.CMD  equ 0A0h
PIC2.DATA equ 0A1h

PIC.EOI   equ 20h
PIC.INIT  equ 11h

; Page Directory Entry
PDE.P		equ 1     ; Present
PDE.W		equ 2     ; Writeable
PDE.U		equ 4     ; User
PDE.PWT		equ 8     ; Page-level Write Through
PDE.PCD		equ 10h   ; Page-level Cache Disable
PDE.A		equ 20h   ; Accessed
PDE.D		equ 40h   ; Dirty
PDE.PS		equ 80h   ; Page Size
PDE.PAT1	equ 80h   ; Page Attribute Table index in 4KiB pages
PDE.G		equ 100h  ; Global
PDE.PAT2	equ 1000h ; Page Attribute Table index in 4MiB pages

; RFLAGS register bits
RFLAGS.IF	equ 1 shl 9  ; Interrupt Enable
RFLAGS.IOPL.1	equ 1 shl 12 ; I/O Privilege Level field
RFLAGS.IOPL.2	equ 1 shl 13 ; ---||---
RFLAGS.NT	equ 1 shl 14 ; Nested Task
;                         15 : 0
RFLAGS.RF	equ 1 shl 16 ; Resume
RFLAGS.VM	equ 1 shl 17 ; Virtual 8086, illegal
RFLAGS.AC	equ 1 shl 18 ; Alignment Check
RFLAGS.VIF	equ 1 shl 19 ; Virtual Interrupt Flag
RFLAGS.VIP	equ 1 shl 20 ; Virtual Interrupt Pending
RFLAGS.ID	equ 1 shl 21 ; If setable, we have cpuid.
;                      22-63 : Reserved
; vim: ts=8 sw=8 syn=nasm
