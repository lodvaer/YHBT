panic:
	cli
	lea rax, [ktty.e_write]
	mov [ktty.write], rax

	mov [ktty.colour], byte 4Fh
	_puts "(PANIC)==> Stack pointer monadic overflow, nyaaaa! <==(PANIC)"
	call debug_print_calltrace
	die

true:
	mov rax, 1
	ret

false:
	xor rax, rax
	ret

error:
	mov rax, -1
	ret

null:
	rep ret

; vim: ts=8 sw=8 syn=fasm
