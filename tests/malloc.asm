;; Tests that verify that malloc is working properly.

;! Test malloc
proc 0, malloc
	mov rdi, 8
	call malloc
	assert rax, ne, -1, "Tests: malloc 1: FAILED"

	mov rdi, rax
	call free

	mov rdi, 8
	call malloc
	assert rax, ne, -1, "Tests: malloc 2: FAILED"

	mov rdi, 10h
	call malloc
	push rax

	mov rdi, rax
	xor rsi, rsi
	mov rdx, 10h
	call memset

	pop rdi
	call free

	mov rdi, 10h
	call malloc
	assert rax, ne, -1, "Tests: malloc 3: FAILED"

	_puts "Malloc: OK!"
	ret
endproc

append tests.torun, this.malloc
; vim: ts=8 sw=8 syn=fasm
