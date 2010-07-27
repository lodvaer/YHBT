;; Queue tests


;! Test put and get of the queue proc interface.
proc 0, queue_proc_putAndGet
	mov r14, 0DEADC0FFEEEEEEEEh
	mov r15, 0DEADBABE1550DEADh
	
	call queue.new
	mov rbx, rax
	mov rdi, rbx
	mov rsi, r14
	call queue.put
	mov rdi, rbx
	mov rsi, r15
	call queue.put

	mov rdi, rbx
	call queue.get
	assert rax, e, r14, "queue_proc_putAndGet: 1"

	mov rdi, rbx
	call queue.get
	assert rax, e, r15, "queue_proc_putAndGet: 2"

	; And in reverse direction:

	mov rdi, rbx
	mov rsi, r15
	call queue.put
	mov rdi, rbx
	mov rsi, r14
	call queue.put

	mov rdi, rbx
	call queue.get
	assert rax, e, r15, "queue_proc_putAndGet: 3"

	mov rdi, rbx
	call queue.get
	assert rax, e, r14, "queue_proc_putAndGet: 4"

	mov rdi, rbx
	call queue.get
	assert rax, e, 0, "queue_proc_putAndGet: 5"

	mov rdi, rbx
	call queue.free

	_puts "queue proc: putAndGet: Yes."
	ret
endproc

;! Test put and get of the queue macro interface.
proc 0, queue_macro_putAndGet
	mov r14, 0DEADC0FFEEEEEEEEh
	mov r15, 0DEADBABE1550DEADh
	
	queue._new
	mov rbx, rax
	
	queue._box r14
	mov rcx, rax
	queue._put r10, rcx->rbx

	queue._box r15
	mov rcx, rax
	queue._put r10, rcx->rbx

	queue._get rbx->rcx, .massive_fail_1
	queue._unbox rcx
	assert rcx, e, r14, "queue_macro_putandGet: 1"


	queue._get rbx->rcx, .massive_fail_2
	queue._unbox rcx
	assert rcx, e, r15, "queue_macro_putandGet: 2"

	queue._get rbx->rcx, .win
	_puts "queue_macro_putandGet: 5"
	jmp panic

.win:
	mov rdi, rbx
	call queue.free

	_puts "queue macro: putAndGet: Very yes."
	ret
.massive_fail_1:
	_puts "queue_macro_putAndGet: 3"
	jmp panic
.massive_fail_2:
	_puts "queue_macro_putAndGet: 4"
	jmp panic
endproc

append tests.torun, this.queue_proc_putAndGet
append tests.torun, this.queue_macro_putAndGet

; vim: ts=8 sw=8 syn=fasm
