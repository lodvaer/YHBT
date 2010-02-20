;; A thread quaject.

Q_THREAD_MAGIC = 0A0712EADh

;! Create a new thread quaject
;: Q Thread
;. q.create
proc 0, q_thread.create
	lea rdi, [q_thread]
	mov esi, q_thread.realsize
	call q.create
	mov edi, eax
	sub [rax + q_thread.resume.addr + 1], eax
	;sub [rax + q_thread.kill.addr + 1], eax
	ret
endproc

;! Clone a thread quaject
;: Q Thread -> Q Thread new_thread : Q Thread old_thread
;. q.clone
proc 0, q_thread.clone
	call q.clone
	mov eax, edi
	sub eax, esi
	sub [rdi + q_thread.resume.addr + 1], eax
	;sub [rdi + q_thread.kill.addr + 1], eax

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
	; If it's blocking on a MVar, the MVar and the queue ticket.
	; Needed to be able to kill the thread.
	var mvar
	var mvar_ticket
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
	;: Int timeslice
	var timeslice

	;: *String
	var root
	;: *String
	var pwd
	;: *String
	var cmd
	;: RBTree
	var fds ; We have the root node integrated into the structure, so this is null
		; specifying no callback
	var fds_tree ; And this is the *RBTree

	;intproc kill
	;	lea rdi, [0]
	;.addr:	jmp 0 ; proc.kill
	;endproc

	intproc resume
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

		mov rbx, cr3
		mov rax, [this.cr3] ; Load the cr3
		cmp rbx, rax	; The rationale for this comparison is the
		je .over	; assumption that the CPU doesn't detect
		mov cr3, rax	; if cr3 changed or not and that the
	.over:			; comparison is faster than invalidating the TLB
		lea rax, [q_thread.start]
		mov ecx, MSR.KGS
		mov rdx, rax
		shr rdx, 32
		wrmsr

		mov r15, [this.r15]
		mov r14, [this.r14]
		mov r13, [this.r13]
		mov r12, [this.r12]
		mov rbx, [this.rbx]
		mov rbp, [this.rbp]
		mov r8,  [this.r8]
		mov r9,  [this.r9]

	.fastreturn:
		mov rdi, [this.timeslice]
		lea rsi, [q_thread.suspend]
	.addr:	call alarm.schedule
		mov [this.alarm], rax

		mov rdi, [this.rdi]
		mov rsi, [this.rsi]
		mov rdx, [this.rdx]
		mov rcx, [this.rcx]
		mov r10, [this.r10]
		mov r11, [this.r11]
		mov rax, [this.rax]

		lea r13, [0]

		iretq
	endproc

	;! Suspend the current thread and call the next.
	;
	; This assumes the stack looks like: (reverse)
	; * Int address it got called from (ignored)
	; * Int rax content
	; * 28h byte interrupt vecor:
	; * * rip
	; * * cs
	; * * rflags
	; * * rsp
	; * * ss
	;
	; If you don't mind loosing rdi, rsi, rdx, rcx, r10, and r11
	; and have allready saved rip, rflags and rsp on the thread,
	; you can use the sub-symbol .nostack
	intproc suspend
		add rsp, 8
		pop qword [this.rax] ; See alarm.tick

		mov [this.rdi], rdi
		mov [this.rsi], rsi
		mov [this.rdx], rdx
		mov [this.rcx], rcx
		mov [this.r10], r10
		mov [this.r11], r11

		lea rax, [0]
		cmp [this.next], rax
		je q_thread.resume.fastreturn
	
		mov rax, [rsp]
		mov r10, [rsp + 8]
		mov rcx, [rsp + 10h]
		mov rdx, [rsp + 18h]
		mov rdi, [rsp + 20h]

		mov [this.rip],    rax
		mov [this.cs],     r10
		mov [this.rflags], rcx
		mov [this.rsp],    rdx
		mov [this.ss],     rdi
	
	.nostack:

		mov qword [this.alarm], 0

		mov [this.r8], r8
		mov [this.r9], r9
		mov [this.r12], r12
		mov [this.r13], r13
		mov [this.r14], r14
		mov [this.r15], r15
		mov [this.rbx], rbx
		mov [this.rbp], rbp


		mov rax, [this.next]
		add rax, this.resume
		jmp rax
	endproc
endquaject

; vim: ts=8 sw=8 syn=fasm
