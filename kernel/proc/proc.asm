


class proc
	;: Int pid
	var cur_pid
	;: RBTree (Q Thread)
	var threads
	;! Initialize a thread queue
	; Makes the caller a new empty thread queue.
	proc init
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
	proc fork
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

		; Return address as landing spot
		; for the thread:
		mov rsi, [rsp + 8]
		mov [rax + q_thread.rip], rsi

		; Insert the cloned before the current:
		mov rdi, [rdx + q_thread.prev]
		mov [rdi + q_thread.next], rax ; NEXT(PREV(rdx)) <- rax
		mov [rax + q_thread.prev], rdi ; PREV(rax) <- PREV(rdx)
		mov [rax + q_thread.next], rdx ; NEXT(rax) <- rdx
		mov [rdx + q_thread.prev], rax ; PREV(rdx) <- rax
		_printreg rax, rdx, rdi
		mov r15, [rax + q_thread.next]
		mov r14, [rax + q_thread.prev]
		mov r13, [rdx + q_thread.next]
		mov r12, [rdx + q_thread.prev]
		_printreg r15, r14, r13, r12

		; Make us the new thread:
		mov rdx, rax
		shr rdx, 32
		mov ecx, MSR.KGS
		wrmsr

		pop rdi
		; TODO: Do stuff like cloning memory, etc.
		xor eax, eax ;  Because we are the new thread.
		ret
	endproc
endclass

; vim: ts=8 sw=8 syn=fasm
