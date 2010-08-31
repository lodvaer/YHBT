;; Syscall interface.

append TO_INIT_64, syscalls.init
macro syscalls.init {
	mov rcx, MSR.LSTAR
	mov eax, syscalls.call
	mov edx, HIGH_HALF shr 32
	wrmsr

	mov rcx, MSR.STAR
	xor eax, eax
	mov edx, SEL_LONG or (SEL_USR_32b shl 16)
	; real syscall cs = SEL_LONG
	; real syscall ss = SEL_LONG    + 8   (SEL_DATA)
	; real sysret  ss = SEL_USR_32b + 8   (SEL_USR_DATA)
	; real sysret  cs = SEL_USR_32b + 10h (SEL_USR_LONG)
	wrmsr

	mov rcx, MSR.SFMASK
	mov eax, (not CFG_NUM_SYSCALLS) and 0FFFFFFFFh
	wrmsr

	lea rax, [syscalls.read]
	mov [syscalls.syscall_0], rax
	lea rax, [syscalls.write]
	mov [syscalls.syscall_1], rax
}

class syscalls
	rept CFG_NUM_SYSCALLS counter:0 {
		ivar syscall_#counter, 0
	}

	;! Syscall handler.
	intproc call
		rol rax, 34
		or  rax, (HIGH_HALF shr 33)
		ror rax, 31
		add rax, this.syscall_0
		jmp qword [rax]
	endproc

	;! read system call
	;: UInt fd -> *Mem buf -> UInt count -> Either (-Error) Int
	proc 0, read
		mov rax, -3 ; -EBADF
		sysretq
	endproc

	;! write system call
	;: UInt fd -> *Mem buf -> UInt count -> Either (-Error) (Int bytes_written)
	proc 0, write
		assert rdi, e, 1, "You can only write to stdout at the moment =P"
		mov rdi, rsi
		mov rsi, rdx
		push rsi
		call ktty.e_write
		pop rax
		sysretq
	endproc

endclass
