;! A lock free FIFO queue
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
;: (Queue a "->" reg) -> Addr empty-> QueueI a
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
;! Put an item into the queue.
;: tmp -> (QueueI a "->" Queue a)
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
		mov rax, tmp
	.over:	lock cmpxchg [queue + 8], reg
	\}
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
	;! Put an item into the queue
	;: Queue a -> a -> IO ()
	;- r10, rsi
	proc 0, put
		push rdi
		mov r10, rsi
		queue._box r10
		mov rsi, rax
		pop rdi
		queue._put r10, rsi->rdi
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

	queue.free = free
endclass

; vim: ts=8 sw=8 syn=fasm
