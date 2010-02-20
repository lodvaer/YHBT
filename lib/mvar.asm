;; MVar implementation, based on the haskell specification.


MVAR_EMPTY_MAGIC = 0DEAD157EC0FFEE00h ; Dead is the coffee.

;: MVar a :: Int count : a

macro mvar.static_newEmpty name {
	match =Y, CFG_CMPXCHG16B \{
		ivar_align 10h
	\}
	ivar name, 0
	ivar name#_content, MVAR_EMPTY_MAGIC
	ivar name#_queue_status, 0
	ivar name#_queue_head, 0
	ivar name#_queue_tail, 0
}
macro mvar.static_new name, val {
	match =Y, CFG_CMPXCHG16B \{
		ivar_align 10h
	\}
	ivar name, 0
	ivar name#_content, val
	ivar name#_queue_status, 0
	ivar name#_queue_head, 0
	ivar name#_queue_tail, 0
}

macro mvar._take onfail {
	mov rax, MVAR_EMPTY_MAGIC
	cmp [rdi + this.CONTENT], rax
	jne .takeIt

	cmp byte [rdi + this.QUEUE_STATUS], this.STATUS_TAKE_PLZ
	jne onfail
	add rdi, this.QUEUE_OFFSET
	call queue.getLocked
	sub rdi, this.QUEUE_OFFSET
	test rax, rax
	jz onfail
	; Take it from the stack of the waiting thread
	; instead of going the way around the MVar.
	mov rsi, [rax + q_thread.rsp]
	mov qword [rax + q_thread.mvar], 0
	push qword [rsi]
	push rcx, rdi
	add qword [rax + q_thread.rsp], 8
	mov rdi, rax
	call proc.schedule
	pop rcx, rdi
	spinunlock saveto->rcx, rdi
	pop rax
	mov edx, 1
	ret

.takeIt:
	mov rax, MVAR_EMPTY_MAGIC
	xchg [rdi + this.CONTENT], rax
	spinunlock saveto->rcx, rdi
	mov edx, 1
	ret
}

macro mvar._put onfail {
	mov rax, MVAR_EMPTY_MAGIC
	cmp [rdi + this.CONTENT], rax
	je .putIt
	
	cmp byte [rdi + this.QUEUE_STATUS], this.STATUS_PUT_PLZ
	jne onfail
	push rsi
	add rdi, this.QUEUE_OFFSET
	call queue.getLocked
	sub rdi, this.QUEUE_OFFSET
	pop rsi
	test rax, rax
	jz onfail
	; Put it into rax of the waiting thread instead of
	; going the way around the MVar itself.
	mov [rax + q_thread.rax], rsi
	mov qword [rax + q_thread.mvar], 0
	push rcx
	mov rdi, rax
	call proc.schedule ; And wake the thread up.
	pop rcx
	spinunlock saveto->rcx, rdi
	mov eax, 1
	ret
.putIt:
	mov [rdi + this.CONTENT], rsi
	spinunlock saveto->rcx, rdi
	mov eax, 1
	ret
}

class mvar
	const SPINLOCK,     0h
	const CONTENT,      8h
	const QUEUE_STATUS, 10h
	const QUEUE_HEAD,   18h
	const QUEUE_TAIL,   20h
	
	const QUEUE_OFFSET, 18h

	const STATUS_GONE,     0
	const STATUS_PUT_PLZ,  1
	const STATUS_TAKE_PLZ, 2
	;! Create a new MVar
	;: a -> IO (MVar a)
	;. malloc
	;- rdi
	; TODO: Alignment.
	proc 0, new
		push rdi
		mov rdi, 28h
		call malloc
		mov qword [rax + this.SPINLOCK], 0
		mov qword [rax + this.QUEUE_STATUS], this.STATUS_GONE
		mov qword [rax + this.QUEUE_HEAD], 0
		mov qword [rax + this.QUEUE_TAIL], 0
		pop qword [rax + this.CONTENT]
		ret
	endproc

	;! Create a new empty MVar
	;: IO (MVar a)
	;. malloc
	;- rdi
	proc 0, newEmpty
		mov rdi, 28h
		call malloc
		mov qword [rax + this.SPINLOCK], 0
		mov qword [rax + this.QUEUE_STATUS], this.STATUS_GONE
		mov qword [rax + this.QUEUE_HEAD],   0
		mov qword [rax + this.QUEUE_TAIL],   0
		mov rdi, MVAR_EMPTY_MAGIC
		mov [rax + this.CONTENT], rdi
		ret
	endproc

	;! Take an MVar
	;: MVar a -> IO a
	proc 0, take
		spinlock saveto->rcx, rdi

		mvar._take .sleep
		
	.sleep:
		push rdi
		xor edi, edi
		call proc.deschedule
		mov rsi, rax
		pop rdi
		push rax
		mov byte [rdi + this.QUEUE_STATUS], this.STATUS_PUT_PLZ
		add rdi, this.QUEUE_OFFSET
		call queue.putLocked
		sub rdi, this.QUEUE_OFFSET
		pop rsi
		mov [rsi + q_thread.mvar], rdi
		mov [rsi + q_thread.mvar_ticket], rax
		spinunlock ignore, rdi
		call proc.descheduled
		ret ; The other thread has put it in our rax <3.
	endproc
	
	;: MVar a -> a -> IO ()
	proc 0, put
		spinlock saveto->rcx, rdi

		mvar._put .sleep
		
	.sleep:
		push rsi ; <- is the value on the stack for the waking thread to take.
		push rdi
		xor edi, edi
		call proc.deschedule
		pop rdi
		bt rcx, 9
		jnc .over
		bts qword [rax + q_thread.rflags], 9
	.over:
		mov rsi, rax
		push rax
		mov byte [rdi + this.QUEUE_STATUS], this.STATUS_TAKE_PLZ
		add rdi, this.QUEUE_OFFSET
		call queue.putLocked
		sub rdi, this.QUEUE_OFFSET
		pop rsi
		mov [rsi + q_thread.mvar], rdi
		mov [rsi + q_thread.mvar_ticket], rax
		spinunlock ignore, rdi
		call proc.descheduled
		ret ; The other thread has taken it from our stack <3
	endproc
	;! Try to take an MVar
	;: MVar a -> IO (Maybe a : Bool)
	; Returns a bool in rdx due to type a being able to be null.
	proc 0, tryTake
		spinlock saveto->rcx, rdi

		mvar._take .fail

	.fail:
		spinunlock saveto->rcx, rdi
		xor edx, edx
		ret
	endproc

	;: MVar a -> a -> IO Bool
	proc 0, tryPut
		spinlock saveto->rcx, rdi
		
		mvar._put .fail
	.fail:
		spinunlock saveto->rcx, rdi
		xor eax, eax
		ret
	endproc

	;: MVar a -> a -> IO a
	proc 0, swap
		push rsi
		call mvar.take
		pop rsi
		push rax
		call mvar.put
		pop rax
		ret
	endproc
endclass

; vim: ts=8 sw=8 syn=fasm
