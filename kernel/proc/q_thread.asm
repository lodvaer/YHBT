;! A thread quaject.

quaject q_thread
	; Doubly linked list.
	var next
	var prev
	; Registers
	var rax, rbx, rcx, rdx, rdi, rsi, rbp, rsp, r8, r9, r10, r11, r12, r13, r14, r15
	; State
	var ss, rsp, rflags, cs, rip, cr3
	; Thread info:

	;
	;: *String
	var root
	;: *String
	var pwd
	;: *RBTree{FD => q_fd}
	var fds

	proc resume
		mov rcx, [this.rcx]
		mov rbx, [this.rbx]
	.fastreturn:
		mov rax, [this.rax]
		iretq
	endproc

	proc suspend
		add rsp, 8
		pop [this.rax] ; See alarm.tick

		mov rax, [this.next]
		cmp [this.prev], rax
		je this.resume.fastreturn

		mov [this.rbx], rbx
		mov [this.rcx], rcx
		mov [this.rdx], rdx
		mov [this.rdi], rdi
		mov [this.rsi], rsi
		mov [this.rbp], rbp
		
	endproc
endquaject

; vim: ts=8 sw=8 syn=fasm
