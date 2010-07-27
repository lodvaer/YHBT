;; Various helper routines and such.

;! Panic.
panic:
	cli
	lea rax, [ktty.e_write]
	mov [ktty.write], rax

	mov [ktty.colour], byte 4Fh
	_puts "(PANIC)==> Stack pointer monadic overflow, nyaaaa! <==(PANIC)"
	lea rdi, [.kgs]
	call kputs
	mov ecx, MSR.KGS
	rdmsr
	shl rdx, 32
	or  rax, rdx
	mov rdi, rax
	call kprinthex
	lea rdi, [.nl]
	call kputs
	call debug_print_calltrace
	die
.kgs:
	db "MSR.KGS: ", 0
.nl:	db 10, 0
idle_sleep:
	xor edx, edx
	xor eax, eax
	mov ecx, MSR.KGS
	wrmsr
	sti
@@:	hlt
	jmp @b

;! Return true.
;: Bool
true:
	mov rax, 1
	ret

;! Return false
;: Bool
false:
	xor rax, rax
	ret

;! Return an error
;: Error
error:
	mov rax, -1
	ret

;! Do nothing but return.
;: ()
null:
	rep ret

;! Leave the current stack frame, returning something.
leaving:
.true:
	mov rax, 1
	leave
	ret

.false:
	xor rax, rax
	leave
	ret

.error:
	mov rax, -1
	leave
	ret

.null:
	leave
	ret
; vim: ts=8 sw=8 syn=fasm
