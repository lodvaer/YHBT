;! A thread quaject.

Q_THREAD_MAGIC = 0A0712EADh

;! Create a new thread quaject
;: Q Thread
;. q.create
proc q_thread.create
	lea rdi, [q_thread]
	mov esi, q_thread.realsize
	call q.create
	mov edi, eax
	sub [rax + q_thread.resume.sched + 1], eax
	ret
endproc

;! Clone a thread quaject
;: Q Thread -> Q Thread new_thread : Q Thread old_thread
;. q.clone
proc q_thread.clone
	call q.clone
	mov eax, edi
	sub eax, esi
	sub [rdi + q_thread.resume.sched + 1], eax

	mov rax, rdi
	mov rdx, rsi
	ret
endproc

quaject q_thread
	dq Q_THREAD_MAGIC ; Magic!
	; Doubly linked list.
	var next
	var prev
	; The alarm ID
	var alarm
	; Registers
	var rax, rbx, rcx, rdx, rdi, rsi, rbp
	var r8, r9, r10, r11, r12, r13, r14, r15
	; State
	var ss
	var cs

	var rip
	var rsp

	var rflags
	var cr3
	; Thread info:
	
	;: Int pid
	var pid
	;: Int tid
	var tid
	;; Int timeslice
	var timeslice

	;: *String
	var root
	;: *String
	var pwd
	;: RBTree
	var fds ; We have the root node integrated into the structure, so this is null
		; speifying no callback
	var fds_tree ; And this is the *RBTree

	proc resume
		mov r15, [this.r15]
		mov r14, [this.r14]
		mov r13, [this.r13]
		mov r12, [this.r12]
		mov r9,  [this.r9]
		mov r8,  [this.r8]
		mov rbx, [this.rbx]
		mov rbp, [this.rbp]

		; Set up the iretq stack.
		mov rax, [this.rip]
		mov rbx, [this.cs]
		mov rcx, [this.rflags]
		mov rdx, [this.rsp]
		mov rdi, [this.ss]

		mov [rsp],       rax
		mov [rsp + 8],   rbx
		mov [rsp + 10h], rcx
		mov [rsp + 18h], rdx
		mov [rsp + 20h], rdi

		mov rax, [this.cr3] ; Load the cr3
		mov cr3, rax
		
		lea rax, [q_thread.start]
		mov ecx, MSR.KGS
		mov rdx, rax
		shr rdx, 32
		wrmsr


	.fastreturn:
		mov rdi, [this.timeslice]
		lea rsi, [q_thread.suspend]
	.sched: call alarm.schedule
		mov [this.alarm], rax

		mov rsi, [this.rsi]
		mov rdi, [this.rdi]
		mov rdx, [this.rdx]
		mov rcx, [this.rcx]
		mov r11, [this.r11]
		mov r10, [this.r10]
		mov rax, [this.rax]
		iretq
	endproc

	proc suspend
		add rsp, 8
		pop qword [this.rax] ; See alarm.tick

		mov [this.r10], r10
		mov [this.r11], r11
		mov [this.rcx], rcx
		mov [this.rdx], rdx
		mov [this.rdi], rdi
		mov [this.rsi], rsi

		lea rax, [0]
		cmp [this.next], rax
		je q_thread.resume.fastreturn

		mov qword [this.alarm], 0

		mov rax, [rsp]
		mov rbx, [rsp + 8]
		mov rcx, [rsp + 10h]
		mov rdx, [rsp + 18h]
		mov rdi, [rsp + 20h]
		
		mov [this.rip],    rax
		mov [this.cs],     rbx
		mov [this.rflags], rcx
		mov [this.rsp],    rdx
		mov [this.ss],     rdi
		
		mov [this.rbp], rbp
		mov [this.rbx], rbx
		mov [this.r8], r8
		mov [this.r9], r9
		mov [this.r12], r12
		mov [this.r13], r13
		mov [this.r14], r14
		mov [this.r15], r15
		
		mov rax, [this.next]
		add rax, this.resume
		jmp rax
	endproc
endquaject

; vim: ts=8 sw=8 syn=fasm
