;; The alarm, a scheduler of jobs.

append TO_INIT_64, alarm.init

macro alarm.init {
	intvector_set (alarm.tick + HIGH_HALF), SEL_LONG, 8F00h, 20h

	mov al, 36h
	out 43h, al
	mov al, (TICK_DIVISOR and 0FFh)
	out 40h, al
	mov al, ((TICK_DIVISOR shr 8) AND 0FFh)
	out 40h, al
}

class alarm
	var ticks
	var list
	;: AlarmJob :: [Int time_left : Proc tocall : *AlarmJob prev]
	const LEFT,   0h
	const TOCALL, 8h
	const PREV,  10h
	const NEXT,  18h
	
	;! Interrupt handler
	;: IO ()
	;+ *
	; Consideration list:
	; SMP: One alarm list per CPU.
	intproc tick
		cli
		push rax
		mov al, 20h
		out 20h, al
;		inc byte [0B8002h]

		mov rax, [this.list]
		cmp rax, 0
		je .out
		
		cmp qword [rax + this.LEFT], 0
		jne .dec

		push rdi
		mov rdi, [rax + this.NEXT]
		mov [this.list], rdi
		mov rdi, rax
		mov rax, [rax + this.TOCALL]
		call free
		pop rdi

		call rax
		pop rax
		iretq
	.dec:
		dec qword [rax + this.LEFT]
	.out:
		pop rax
		iretq
	endproc

	;! Schedule a procedure to be called when $1 ticks has passed
	;: Int time -> *Proc to schedule -> IO(Int) id
	;- rax, rdx, rdi, rsi, r10, r11
	; TODO:
	;  - Anything better than an O(n) scheduler?
	proc 0, schedule
		assert rsi, ne, 0, "alarm.schedule: rsi == 0!"
		assert rdi, le, 267840000, "alarm.schedule: Scheduling for longer than a month!"


		mov rdx, rdi ; Create the new node
		mov r10, rsi
		mov rdi, 20h
		call malloc
		mov [rax + this.TOCALL], r10 ; And move proc to it's rightfull place
		
		lea r11, [this.list - 18h]
		mov r10, [this.list]
	.loop:
		cmp r10, 0
		je .last

		mov rsi, [r10 + this.LEFT]

		cmp rdx, rsi
		jle .win
	
		sub rdx, rsi

		mov r11, r10
		mov r10, [r10 + this.NEXT]
		jmp .loop


	.win:	; Nt <= Jt
		sub rsi, rdx
		mov [r10 + this.LEFT], rsi
		mov rsi, [r10 + this.PREV]
		mov [rax + this.PREV], rsi ; PREV(rax) <- PREV(r10)
		mov [r10 + this.PREV], rax ; PREV(r10) <- rax
		mov [rsi + this.NEXT], rax ; NEXT(PREV(r10)) <- rax
		mov [rax + this.NEXT], r10 ; NEXT(rax) <- r10
		mov [rax + this.LEFT], rdx
		ret

	.last:
		mov [rax + this.LEFT], rdx
		mov [rax + this.PREV], r11     ; PREV(rax)  <- prev
		mov qword [rax + this.NEXT], 0 ; NEXT(rax)  <- 0
		mov [r11 + this.NEXT], rax     ; NEXT(prev) <- rax
		ret
	endproc

	;! Deschedule an alarm
	;: Int id -> IO ()
	;- rsi, rax
	proc 0, deschedule
		mov rsi, [rdi + this.NEXT] ; rsi <- NEXT(rdi)
		mov rax, [rdi + this.PREV]
		mov [rax + this.NEXT], rsi ; NEXT(PREV(rdi)) <- NEXT(rdi)
		cmp rsi, 0
		je  .free

		mov rax, [rdi + this.LEFT]
		add [rsi + this.LEFT], rax ; TIME_LEFT(NEXT(rdi)) += TIME_LEFT(rdi)

		mov [rsi + this.PREV], rax ; PREV(NEXT(rdi)) <- PREV(rdi)
		tailcall free
	.free:	nop
		tailcall free
	endproc
endclass

; vim: ts=8 sw=8 syn=fasm
