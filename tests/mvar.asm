;; MVar tests

;! Test that tryTake works.
proc 0, mvar_tryTake
	lea rdi, [.take]
	call mvar.tryTake
	assert rdx, e, 1, "MVar tryTake: Didn't return true."
	assert rax, e, 55h, "MVar tryTake: Didn't return 55."
	_puts "MVar tryTake: Gotcha."
	ret
align 10h
mvar.static_new mvar_tryTake.take, 55h
endproc

;! Test that tryPut works
proc 0, mvar_tryPut
	lea rdi, [.put]
	mov esi, 55h
	call mvar.tryPut
	assert rax, e, 1, "MVar tryPut: Didn't return true."
	_puts "MVar tryPut: Positive."
	ret
align 10h
mvar.static_newEmpty mvar_tryPut.put
endproc

;! Test that both tryTake and tryPut works.
proc 0, mvar_tryBoth
	push rbx
	mov rbx, 0DEADBABE1550DEADh
	lea rdi, [.both]
	mov rsi, rbx
	call mvar.tryPut
	assert rax, e, 1, "MVar tryBoth: Put 1 didn't return true 1."
	lea rdi, [.both]
	call mvar.tryTake
	assert rdx, e, 1, "MVar tryBoth: Take 1 didn't return true."
	assert rax, e, rbx, "MVar tryBoth: Take 1 didn't return correct value."

	add rbx, 4276578
	rol rbx, 32
	add rbx, 1342411
	rol rbx, 13

	lea rdi, [.both]
	mov rsi, rbx
	call mvar.tryPut
	assert rax, e, 1, "MVar tryBoth: Put 2 didn't return true 1."
	lea rdi, [.both]
	call mvar.tryTake
	assert rdx, e, 1, "MVar tryBoth: Take 2 didn't return true."
	assert rax, e, rbx, "MVar tryBoth: Take 2 didn't return correct value."
	_puts "Mvar tryBoth: ^_^"
	ret
align 10h
mvar.static_newEmpty mvar_tryBoth.both
endproc

append tests.torun, this.mvar_tryTake
append tests.torun, this.mvar_tryPut
append tests.torun, this.mvar_tryBoth
; vim: ts=8 sw=8 syn=fasm
