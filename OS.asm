;; Main OS entry point.

include 'OS.cfg'
include 'include/macros.h'
include 'include/cpu.h'
include 'include/constants.h'
include 'include/mm.h'

TO_INIT_64 equ
TO_INIT_32 equ
TO_INIT_16 equ
TO_IVAR equ

org 1000h
_START:
use16
	jmp init
use64

; The order of inclusion matters _a lot_.

include 'lib/assert.asm'   ; Needed by mostly everything.
include 'lib/string.asm'
include 'lib/debug.asm'
include 'lib/rbtree.asm'

include 'kernel/q.asm'
include 'kernel/proc/proc.asm'
include 'kernel/proc/q_thread.asm'
include 'kernel/mm.asm'
include 'kernel/misc.asm'
include 'kernel/tables.asm'
include 'kernel/ktty.asm'
include 'kernel/ints.asm'
include 'kernel/syscalls.asm'
include 'kernel/vfs.asm'
include 'kernel/alarm.asm' ; Needs kernel/ints
include 'lib/stdlib.asm'   ; Needs kernel/mm
include 'lib/queue.asm'    ; Needs stdlib
include 'lib/mvar.asm'     ; Needs queue



match =Y, CFG_TTY_TEXT {
;	include 'drivers/tty/text.asm'
}
match =Y, CFG_TTY_VESA {
;	include 'drivers/tty/vesa.asm'
}
match =Y, CFG_VFS {
;	include 'servers/vfs.asm'
}
kmain:
	; Clean the init-code and initialize
	; the vars to 0
	lea rdi, [_VARS]
	xor rsi, rsi
	mov edx, _END - _VARS
	call memset
	; Only after we have cleared memory is it safe to enable interrupts,
	; because stuff like the clock needs its variables zeroed.
	sti

match =Y, CFG_TESTRUN {
	include 'tests/main.asm'
}
	lea rax, [.t0]
	push rax
	jmp proc.init
.t0:	; We are here in thread 0.

	call proc.execve
	xor bx, bx
	mov rax, 50DEADBEEF5h
	mov rax, [rax]
	jmp .t0
align 8

align 64 ; So it's on a different cache line.
_IVARS:
match I, TO_IVAR {
	irp do_ivar, I \{
		do_ivar
	\}
}
align 8
_VARS:
init:
include 'init/main.asm'
_END:
; vim: ts=8 sw=8 syn=fasm
