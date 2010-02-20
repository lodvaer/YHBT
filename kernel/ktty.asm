;; Kernel TTY-functions.

class ktty
	ivar write, (HIGH_HALF + ktty.e_write)
	ivarb colour, 05Fh
	varb x
	varb y

	;! Internal kernel puts-function
	;: *0Char str -> IO ()
	;. write
	;= kputs
	proc 0, kputs
	kputs = this.kputs
		xor eax, eax
		call strlen
		mov rsi, rax
		tailcall qword [this.write]
	endproc
	;! Print an address
	;: Int addr -> IO ()
	;. write
	;= kprintaddr
	intproc kprintaddr
	kprintaddr = this.kprintaddr
		; As there is no point unless there's a symbol table loaded,
		; fallthrough to the next, which is:
	endproc
	;! Print a number in hexadecimal
	;: Int n -> IO ()
	;- di, si
	;. write
	;= kprinthex
	proc 0, kprinthex, 14->CNT, 15->NUM
	kprinthex = this.kprinthex
	varb hexbuf ; Stack, you idiot.
		push rCNT, rNUM
		mov rNUM, rdi
		xor rCNT, rCNT

		lea rdi, [.str]
		mov esi, 2
		call qword [this.write]
		; A malloc-free version: (it wasn't stable when I wrote it)
	.loop:
		rol rNUM, 4
		mov al, rNUMb
		and al, 0Fh

		cmp al, 10
		jae .hex
	.dec:
		add al, 30h
		jmp .over
	.hex:
		add al, 37h
	.over:	mov [this.hexbuf], al
		lea rdi, [this.hexbuf]
		mov esi, 1
		call qword [this.write]
		inc rCNT
		cmp rCNT, 64/4
		jne .loop
		pop rCNT, rNUM
		ret

	.str:	db "0x"
	endproc
	
	;! Write a byte to the screen
	;: Word <Char attr:Char chr> -> IO ()
	;- a, d
	; the e_ is for early.
	proc 0, e_putc
		cmp dil, 10
		je .newline

		xor edx, edx
		mov rax, HIGH_HALF + 0B8000h
		mov dl, [this.x]
		shl edx, 1
		add rax, rdx
		mov dl, [this.y]
		shl edx, 5
		add rax, rdx
		shl edx, 2
		add rax, rdx

		mov [rax], di
		inc byte [this.x]
		cmp byte [this.x], 80
		je .newline
		ret

	.newline:
		mov byte [this.x], 0
		inc byte [this.y]
		cmp byte [this.y], 25
		retne

		add byte [this.colour], 10h
		mov byte [this.y], 0
		ret
	endproc
	;! Write a byte to the early tty.
	;: *Char str -> Int size -> IO ()
	;- di, si, r10
	;. ktty.e_putc
	; A guaranteed working write to print something on the screen.
	proc 0, e_write
		cmp rsi, 0
		rete
		mov r10, rdi
		mov dil, [this.colour]
		shl di, 8
	.loop:
		mov dil, [r10]
		call this.e_putc
		inc r10
		dec rsi
		jnz .loop
		ret
	endproc
endclass

; vim: ts=8 sw=8 syn=fasm
