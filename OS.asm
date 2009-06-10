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

include 'lib/assert.asm'
include 'lib/string.asm'
include 'lib/stdlib.asm'
include 'lib/debug.asm'

include 'kernel/mm.asm'
include 'kernel/misc.asm'
include 'kernel/tables.asm'
include 'kernel/ktty.asm'
include 'kernel/ints.asm'
include 'kernel/alarm.asm'


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
	; because stuff like the clock needs it's variables zeroed.
	sti

CALLTRACE_ACTIVE = CALLTRACE
	; Testing components at the moment go here:


@@:	hlt
	jmp @b

tst1:
	_puts "Hello, A"
	ret
tst2:
	_puts "Hello, B"
	ret
tst3:
	_puts "Hello, C"
	ret

align 64 ; So it's on a different cache line.
_IVARS:
match I, TO_IVAR {
	irp do_ivar, I \{
		do_ivar
	\}
}
_VARS:
init:
include 'init/main.asm'
_END:
; vim: ts=8 sw=8 syn=fasm
