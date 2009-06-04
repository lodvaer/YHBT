panic:
	cli
;	mov [tty.text.colour], byte 4Fh
	_puts "(PANIC)==> Stack pointer monadic overflow, nyaaaa! <==(PANIC)"
	call debug_print_calltrace
	die

true:
	mov rax, 1
	ret

false:
	mov rax, 0
	ret

error:
	mov rax, -1
	ret

null:
	rep ret

; vim: ts=8 sw=8 syn=fasm
