;; 
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
	
	;; Interrupt handler
	;: IO ()
	; Consideration list:
	; SMP
	proc tick
		push rax
		mov al, 20h
		out 20h, al
;		inc byte [0B8002h]

		mov rax, [this.list]
		cmp rax, 0
		je .out
		
		cmp qword [rax], 0
		jne .dec

		push rdi
		mov rdi, [rax + 18h]
		mov [this.list], rdi
		mov rdi, rax
		mov rax, [rax + 8]
		call free
		pop rdi

		call rax
		pop rax
		iretq
	.dec:
		dec qword [rax]
	.out:
		pop rax
		iretq
	endproc

	;; Schedule a procedure to be called when time ticks has passed
	;: Int time -> *Proc procedure -> IO Int id
	;- rax, rdx, rdi, rsi, r10, r11
	; TODO:
	;  - Anything better than an O(n) scheduler?
	;  - Semaphore
	proc schedule
		assert rsi, ne, 0, "alarm.schedule: rsi == 0!"
		assert rdi, le, 2678400, "alarm.schedule: Sleeping for longer than a month!"


		mov rdx, rdi ; Create the new node
		mov r10, rsi
		mov rdi, 20h
		call malloc
		mov [rax + 8], r10 ; And move proc to it's rightfull place
		
		lea r11, [this.list - 18h]
		mov r10, [this.list]
	.loop:
		cmp r10, 0
		je .last

		mov rsi, [r10]

		cmp rdx, rsi
		jle .win
	
		sub rdx, rsi

		mov r11, r10
		mov r10, [r10 + 18h]
		jmp .loop


	.win:	; Nt <= Jt
		sub rsi, rdx
		mov [r10], rsi
		mov rsi, [r10 + 10h]
		mov [rax + 10h], rsi ; PREV(rax) <- PREV(r10)
		mov [r10 + 10h], rax ; PREV(r10) <- rax
		mov [rsi + 18h], rax ; NEXT(PREV(r10)) <- rax
		mov [rax + 18h], r10 ; NEXT(rax) <- r10
		mov [rax], rdx
		ret

	.last:
		mov [rax], rdx
		mov [rax + 10h], r11     ; PREV(rax)  <- prev
		mov qword [rax + 18h], 0 ; NEXT(rax)  <- 0
		mov [r11 + 18h], rax     ; NEXT(prev) <- rax
		ret
	endproc

	;; Deschedule an alarm
	;: Int id -> IO ()
	;- rsi, rax
	; TODO:
	;  - Semaphore
	proc deschedule
		mov rsi, [rdi + 18h] ; rsi <- NEXT(rdi)
		mov rax, [rdi]
		add [rsi], rax ; TIME_LEFT(NEXT(rdi)) += TIME_LEFT(rdi)
		mov rax, [rdi + 10h]

		mov [rax + 18h], rsi ; NEXT(PREV(rdi)) <- NEXT(rdi)

		cmp rsi, 0
		je  free
		
		mov [rsi + 10h], rax ; PREV(NEXT(rdi)) <- PREV(rdi)
		jmp free
	endproc
endclass

; vim: ts=8 sw=8 syn=fasm