;; A lock free FIFO queue
; One macro interface and one common procedural.
; In the procedural, boxing into queue elements is given,
; in the macro you have to do it yourself with the macros.

;: Queue a :: QueueI a head : QueueI a tail
;: QueueI a :: [a]

;! Create a new queue
;: Queue a
;. malloc
macro queue._new {
	mov edi, 10h
	call malloc
	mov qword [rax], 0
	mov qword [rax + 8], 0
}
;! Box a value into a queue element
;: a (not in [rdi, rsi, rax]) -> QueueI a (in rax)
;- rdi
;. malloc
macro queue._box what {
	mov edi, 10h
	call malloc
	mov qword [rax], what
	mov qword [rax + 8], 0
}
;! Unbox a value
;: QueueI a (not in rdi) -> a (in the same register)
;- rdi
macro queue._unbox what {
	mov rdi, what
	mov what, [what]
	_free rdi
}
;! Get an item from the queue into an register
;: (queue a "->" reg) -> Addr empty-> QueueI a
;- rax
macro queue._get what, empty {
	local .back, .over
	match queue->reg, what \{
	.back:	mov rax, [queue]
		test rax, rax
		jz empty
		mov reg, [rax + 8]
		lock cmpxchg [queue], reg
		jnz .back
		test reg, reg
		jnz .over
		mov qword [queue + 8], 0
	.over:	mov reg, rax
	\}
}
;! Get an item from the queue while in a spinlock (no "lock cmpxchg")
;: (Queue a "->" Reg reg) -> Addr empty-> QueueI a previous
;- rax
macro queue._getLocked what, empty {
	local .over
	match queue->reg, what \{
		mov reg, [queue]
		test reg, reg
		jz empty
		mov rax, [reg + 8]
		mov [queue], rax
		test rax, rax
		jnz .over
		mov qword [queue + 8], 0
	.over:
	\}
}

;! Put an item into the queue.
;: Reg tmp -> (QueueI a "->" Queue a) -> QueueI current in reg
macro queue._put tmp, what {
	local .back, .empty, .over
	match reg->queue, what \{
	.back:	mov tmp, [queue + 8]
		test tmp, tmp
		jz .empty
		xor eax, eax
		lock cmpxchg [tmp + 8], reg
		jz .over
		mov rax, tmp
		mov tmp, [tmp + 8]
		lock cmpxchg [queue + 8], tmp
		jmp .back
	.empty:	xor eax, eax
		lock cmpxchg [queue], reg
	.over:	mov rax, tmp
		lock cmpxchg [queue + 8], reg
	\}
}
;! Put an item into the queue while in a spinlock (no "lock cmpxchg")
;: Reg tmp -> (QueueI a "->" Queue a) -> QueueI current in reg
macro queue._putLocked tmp, what {
	local .empty, .over
	match reg->queue, what \{
		mov tmp, [queue + 8]
		test tmp, tmp
		jz .empty
	.back:	xor eax, eax
		cmpxchg [tmp + 8], reg
		jz .over
		mov tmp, rax
		jmp .back
	.empty:	mov [queue], reg
	.over:	mov [queue + 8], reg
	\}
}

;! Delete an item from the queue from within a spinlock.
;: Reg tmp -> Queue a -> QueueI what -> IO ()
;. _free
;- rax
macro queue._deleteLocked tmp, queue, what {
	local .del, .zero, .over
	mov tmp, [what + 8]
	test tmp, tmp
	jz .del
	mov rax, [tmp]
	mov [what], rax
	mov rax, [tmp + 8]
	mov [what + 8], rax
	_free tmp
	jmp .over
.del:	_free what
	mov rax, [queue]
	cmp [queue + 8], rax
	je .zero
	mov [queue + 8], rax ; Set the last to the first so the next put becomes O(n).
	jmp .over
.zero:	mov qword [queue], 0
	mov qword [queue + 8], 0
.over:
}


class queue
	const Queue.head, 0
	const Queue.tail, 8

	const QueueI.value, 0
	const QueueI.next,  8

	;! Make a new queue
	;: Queue a
	;. malloc
	proc 0, new
		queue._new
		ret
	endproc

	queue.free = free

	;! Put an item into the queue
	;: Queue a -> a -> IO (QueueI a (delete ticket))
	;- r10, rsi, rax
	proc 0, put
		push rdi
		mov r10, rsi
		queue._box r10
		mov rsi, rax
		pop rdi
		queue._put r10, rsi->rdi
		mov rax, rsi
		ret
	endproc
	;! Put an item into the queue while spinlocked.
	;: Queue a -> a -> IO (QueueI a (delete ticket))
	;- r10, rsi, rax
	proc 0, putLocked
		push rdi
		mov r10, rsi
		queue._box r10
		mov rsi, rax
		pop rdi
		queue._putLocked r10, rsi->rdi
		mov rax, rsi
		ret
	endproc
	;! Get an item from the queue
	;: Queue a -> IO (Maybe a)
	;- rsi
	proc 0, get
		queue._get rdi->rsi, .fail
		mov rax, [rsi]
		_free rsi
		ret
	.fail:	xor eax, eax
		ret
	endproc
	;! Get an item from the queue while spinlocked.
	;: Queue a -> IO (Maybe a)
	;- rsi
	proc 0, getLocked
		queue._getLocked rdi->rsi, .fail
		mov rax, [rsi]
		_free rsi
		ret
	.fail:	xor eax, eax
		ret
	endproc

	;! Delete an item from the queue given the previous item
	;: QueueI a -> IO ()
	;- rax, rsi, rdi
	proc 0, delete
		lea rdi, [.msg]
		call kputs
		tailcall panic
	.msg:	db "queue.delete not implemented.", 0
	endproc
	;! Delete an item from the queue given the previous item from within a spinlock
	;: Queue a -> QueueI a -> IO ()
	;- rax, rsi, rdi, r10
	proc 0, deleteLocked
		queue._deleteLocked r10, rdi, rsi
		ret
	endproc
endclass

; vim: ts=8 sw=8 syn=fasm
