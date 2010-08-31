;; /sbin/init

SYS_WRITE = 1
stdout = 1

use64
org 2000000h
start:
	xchg bx, bx
	mov rdi, stdout
	mov rsi, txt
	mov rdx, txt.length
	mov rax, SYS_WRITE
	syscall
.loop:
	rep nop
	jmp .loop

txt:	db '"Hello, world!" from luserspace!', 10
txt.length = $ - txt
; vim: ts=8 sw=8 syn=fasm
