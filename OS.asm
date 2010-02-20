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
	call mvar.newEmpty
	mov [whut], rax

	call proc.fork
	cmp rax, 0
	je .child1

	xor rbp, rbp
	mov rbx, 0
@@:	dec rbx
	mov rsi, rbx
	mov rdi, [whut]
	call mvar.put
	jmp @b


.child1:
	call proc.fork
	cmp rax, 0
	je .child2
	xor rbp, rbp
	sub rsp, 200h
	mov rbx, 0
@@:	inc rbx
	mov rdi, [whut]
	mov rsi, rbx
	call mvar.put
	jmp @b

.child2:
	xor rbp, rbp
	sub rsp, 400h
@@:	xchg bx, bx
	mov rdi, [whut]
	call mvar.take
	_puts "Got ", rax
	jmp @b

align 64 ; So it's on a different cache line.
whut:	dq 0
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
