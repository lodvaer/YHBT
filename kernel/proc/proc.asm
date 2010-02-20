


class proc
	;: Int pid
	var cur_pid
	;: RBTree (Q Thread)
	var threads
	;! Initialize a thread queue
	; Makes the caller a new empty thread queue.
	intproc init
		call q_thread.create
		mov rdi, rax
		mov [rax + q_thread.next], rax
		mov [rax + q_thread.prev], rax

		mov rax, cr3
		mov [rdi + q_thread.cr3], rax
		mov eax, cs
		mov [rdi + q_thread.cs], rax
		mov eax, ss
		mov [rdi + q_thread.ss], rax
		pushf
		pop rax
		mov [rdi + q_thread.rflags], rax
		mov rax, HIGH_HALF + 8FFF8h
		mov [rdi + q_thread.rsp], rax

		mov eax, 1
		lock xadd [this.cur_pid], rax
		mov [rdi + q_thread.pid], rax

		pop rax
		mov [rdi + q_thread.rip], rax
		lea rax, [rdi + q_thread.resume]
		sub rsp, 20h
		jmp rax
	endproc

	;! Fork the current thread into two.
	;: Int what -> Int pid
	;- *
	; Some trickery is involved. As it's better to
	; run the forked child first, the new cloned one becomes the parent.
	proc -1, fork
		push rdi

		;swapgs
		;lea rdi, [gs:dword 0] ; Doesn't work in emulators, how about real HW?
		;swapgs
		mov ecx, MSR.KGS
		rdmsr
		shl rdx, 32
		mov edi, eax
		or  rdi, rdx
if ASSERT
		push r10, r11
		mov r11, Q_THREAD_MAGIC
		mov r10, [rdi]
		assert r10, e, r11, "proc.fork: Not a valid thread in KGS D="
		pop r10, r11
end if
		call q_thread.clone
if ASSERT
		push r10, r11
		mov r11, Q_THREAD_MAGIC
		mov r10, [rax]
		assert r10, e, r11, "proc.fork: Original thread died in cloning!"
		mov r10, [rdx]
		assert r10, e, r11, "proc.fork: Didn't clone right!"
		pop r10, r11
end if
		mov esi, 1
		lock xadd [this.cur_pid], rsi
		mov [rdx + q_thread.pid], rsi
		mov [rax + q_thread.rax], rsi

		mov [rax + q_thread.r12], r12 ; Save the current context
		mov [rax + q_thread.r13], r13 ; to the new thread
		mov [rax + q_thread.r14], r14
		mov [rax + q_thread.r15], r15
		mov [rax + q_thread.rbx], rbx
		mov [rax + q_thread.rbp], rbp

		; Return address as landing spot
		; for the thread:
		mov rsi, [rbp + 8]
		mov [rax + q_thread.rip], rsi

		; Insert the cloned before the current:
		mov rdi, [rdx + q_thread.prev]
		mov [rdi + q_thread.next], rax ; NEXT(PREV(rdx)) <- rax
		mov [rax + q_thread.prev], rdi ; PREV(rax) <- PREV(rdx)
		mov [rax + q_thread.next], rdx ; NEXT(rax) <- rdx
		mov [rdx + q_thread.prev], rax ; PREV(rdx) <- rax

		pop rdi
		; TODO: Do stuff like cloning memory, etc.
		xor eax, eax ;  Because we are the new thread.
		ret
	endproc

	;! Give way for the next procedure.
	;- rax, rdi, rsi, rdx, rcx, r10, r11
	intproc yield
		mov ecx, MSR.KGS
		rdmsr
		shl rdx, 32
		or  rax, rdx
		pushf
		pop rcx
		cli
		mov [rax + q_thread.rflags], rcx
	.lnd:	pop rcx
		mov [rax + q_thread.rip], rcx
		mov [rax + q_thread.rsp], rsp
		mov rdi, [rax + q_thread.alarm]
		push rax
		call alarm.deschedule
		pop rax
		sub rsp, 38h
		add rax, q_thread.suspend.nostack
		jmp rax
	endproc

	;! After you're done with the reschedule-addr from deschedule, yield with this.
	;. proc.yield
	intproc descheduled
		mov ecx, MSR.KGS
		rdmsr
		shl rdx, 32
		or  rax, rdx
		jmp proc.yield.lnd
	endproc

	;! Schedule the given thread for execution before the current
	;: Thread a -> IO ()
	proc 0, schedule
		mov ecx, MSR.KGS
		rdmsr
		shl rdx, 32
		or  rax, rdx
	if ASSERT
		assert rdi, ne, rax, "proc.schedule: The thread to schedule is the same as the current one."
		push r10, r11
		mov r10, Q_THREAD_MAGIC
		mov r11, [rdi]
		assert r10, e, r11, "proc.schedule: Thread to schedule is invalid."
		mov r11, [rax]
		assert r10, e, r11, "proc.schedule: Current thread is invalid."
		pop r10, r11
	end if
		mov rdx, [rax + q_thread.next] ; Schedule next
		mov [rdx + q_thread.prev], rdi
		mov [rdi + q_thread.next], rdx
		mov [rax + q_thread.next], rdi
		mov [rdi + q_thread.prev], rax

		;mov rdx, [rax + q_thread.prev] ; Schedule last
		;mov [rdi + q_thread.next], rax
		;mov [rdi + q_thread.prev], rdx
		;mov [rax + q_thread.prev], rdi
		;mov [rdx + q_thread.next], rax

		ret
	endproc

	;! Deschedule the given thread
	;: Maybe (Q Thread) -> IO (Q Thread)
	proc 0, deschedule
		cli
		test rdi, rdi
		jnz .over
		mov ecx, MSR.KGS
		rdmsr
		shl rdx, 32
		mov edi, eax
		or  rdi, rdx
	.over:
	if ASSERT
		push r10, r11
		mov r11, Q_THREAD_MAGIC
		mov r10, [rdi]
		assert r10, e, r11, "proc.deschedule: Invalid thread."
		pop r10, r11
	end if
		mov rcx, [rdi + q_thread.next]
		cmp rcx, rdi
		je .del
		mov rdx, [rdi + q_thread.prev]
		mov rax, rdi
		cmpxchg [rdx + q_thread.next], rcx
		jnz .over
		mov [rcx + q_thread.prev], rdx
		mov rax, rdi
		ret
	.del:
		mov rax, rdi
		lea rcx, [idle_sleep - q_thread.resume]
		cmpxchg [rdi + q_thread.next], rcx
		jnz .over
		mov rax, rdi
		ret
	endproc
endclass

; vim: ts=8 sw=8 syn=fasm
