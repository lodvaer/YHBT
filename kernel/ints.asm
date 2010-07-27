;; Interrupts.

CALLTRACE equ N

append TO_INIT_64, ints.init
macro ints.init {
	mov al, PIC.INIT
	out PIC1.CMD, al
	out PIC2.CMD, al
	mov al, 20h
	out PIC1.DATA, al	; IRQ 0-7:  20h-27h
	mov al, 28h
	out PIC2.DATA, al	; IRQ 7-Fh: 28h-2Fh
	mov al, 4
	out PIC1.DATA, al
	mov al, 2
	out PIC2.DATA, al
	mov al, 1
	out PIC1.DATA, al
	out PIC2.DATA, al

	in al, PIC1.DATA
	mov al, 11111100b
	out PIC1.DATA, al
	in al, PIC2.DATA
	mov al, 11111111b
	out PIC2.DATA, al

	mov rdi, HIGH_HALF
	mov rcx, 512
	intvector_setregs (ints.null + HIGH_HALF), SEL_LONG, 8F00h
@@:
	mov [rdi + rcx * 8 - 16], rax
	mov [rdi + rcx * 8 - 8], rbx
	dec rcx
	loop @b

	lidt [IDTR]
}
include 'kernel/faults/main.asm'

class ints
	;! The null interrupt, i.e. unhandled.
	;: IO ()
	; Increments top left corner.
	intproc null
		push rax
		mov al, 20h
		out 20h, al
		inc byte [0B8000h]
		pop rax
		iretq
	endproc
endclass

restore CALLTRACE
; vim: ts=8 sw=8 syn=fasm
