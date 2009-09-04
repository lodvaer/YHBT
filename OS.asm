include 'OS.cfg'
include 'include/macros.h'
include 'include/cpu.h'
include 'include/constants.h'

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

include 'lib/assert.asm'
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
include 'kernel/alarm.asm' ; Needs kernel/ints
include 'lib/stdlib.asm'   ; Needs kernel/mm


match =Y, CFG_TTY_TEXT {
;	include 'drivers/tty/text.asm'
}
match =Y, CFG_TTY_VESA {
;	include 'drivers/tty/vesa.asm'
}
match =Y, CFG_VFS {
;	include 'servers/vfs.asm'
}
CALLTRACE_ACTIVE = 0
kmain:
	; Clean the init-code and initialize
	; the vars to 0
	lea rdi, [_VARS]
	xor rsi, rsi
	mov edx, _END - _VARS
	call memset
	; Only after we have cleared memory is it safe to enable interrupts,
	; because stuff like the clock needs it's variables zeroed.
	sti

match =Y, CFG_TESTRUN {
	include 'tests/main.asm'
}

CALLTRACE_ACTIVE = CALLTRACE
	lea rax, [.t0]
	push rax
	jmp proc.init
.t0:	; We are here in thread 0.
	call proc.fork
	cmp rax, 0
	je .child

.parent:
	_puts "The parent is alive!"
	_printreg rax
	lea r14, [A]
@@:	mov rdi, r14
	cli
	call kputs
	sti
	hlt
	jmp @b

.child:
	_puts "The child is here!"
	lea r15, [B]
@@:	mov rdi, r15
	cli
	call kputs
	sti
	hlt
	jmp @b


A:	db 'A', 0
B:	db 'B', 0

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
