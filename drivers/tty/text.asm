;; NOT A VALID REPRESENTATION OF A DRIVER!

TTY_TEXT_VIDEO_MEM equ 0B8000h

match =M, CFG_TTY_TEXT {
	include '../../OS.symb'
	TTY_TEXT_VIDEO_OFFSET equ TTY_TEXT_VIDEO_MEM + IDENT_MAP
}
match =P, CFG_TTY_TEXT {
	include '%FASMINC%std.asm'
	include '%FASMINC%.asm'

	; Map video memory into RAM
	; Set the MTRRs, etc.
	TTY_TEXT_VIDEO_OFFSET equ TTY_TEXT_VIDEO_MEM + 2*1024*1024
}
match =Y, CFG_TTY_TEXT {
	TTY_TEXT_VIDEO_OFFSET equ TTY_TEXT_VIDEO_MEM + 2*1024*1024
	append TO_INIT_64, tty.text.init
	macro tty.text.init
	\{
		; Initialization goes here
	\}
}
;! A classical 80x25 text-mode terminal
class tty.text
	varb colour
	;! Put a character on the screen
	;: Int x -> Int y -> Char c -> IO ()
	;- rdi, rsi
	proc 0, putc
		assert rdi, ge, 0, "putc: X is negative!"
		assert rsi, ge, 0, "putc: Y is negative!"
		assert rdi, le, 80, "putc: X more than 80!"
		assert rsi, le, 25, "putc: Y more than 25!"
		
		shl rdi, 1
		shl rsi, 5
		add rdi, rsi
		shl rsi, 2
		add rdi, rsi ; rdi = x*2 + y*160

		mov rsi, TTY_TEXT_VIDEO_OFFSET
		add rsi, rdi
		
		mov dh, [this.colour]
		mov byte [rsi], dl
		ret
	endproc
	
	;! Write a continous stream of characters
	;: Int x -> Int y -> Int num -> *Char string -> IO ()
	proc 0, write, d->NUM
		assert rdi, g, 0, "write: num is 0!"
		assert rdi, ge, 0, "write: X is negative!"
		assert rsi, ge, 0, "write: Y is negative!"
		assert rdi, le, 80, "write: X more than 80!"
		assert rsi, le, 25, "write: Y more than 25!"

		shl rdi, 1
		shl rsi, 5
		add rdi, rsi
		shl rsi, 2
		add rdi, rsi ; rdi = x*2 + y*160

		mov rsi, TTY_TEXT_VIDEO_OFFSET
		add rdi, rsi
		
		mov esi, ecx

		mov ah, [this.colour]
	.loop:
		lodsb
		stosd
		dec rNUMd
		jnz .loop

		ret
	endproc

	;! Set the colour to use
	;: Char colour -> IO ()
	proc 0, set_colour
		mov [this.colour], dil
		ret
	endproc

	;! Clear the screen
	;: IO ()
	;- rax, rcx, rdi
	proc 0, reset
		xor eax, eax
		mov rdi, TTY_TEXT_VIDEO_OFFSET
		mov ecx, 25*80*2 / 4
		rep stosd
		ret
	endproc

	;! Save in image of the screen
	;: *Mem image
	;. malloc
	;- rax, rdx, rdi, rsi
	proc 0, save
		mov edi, 25*80*2
		mov edx, edi
		shr edx, 2
		call malloc
		mov rdi, rax
		mov rsi, TTY_TEXT_VIDEO_OFFSET

	.loop:
		lodsd
		stosd
		dec edx
		jnz .loop
		
		ret
	endproc

	;! Reinstate the screen from an image
	;: *Mem image -> IO ()
	;- rax, rdx, rdi, rsi
	proc 0, reinstate
		mov edx, 25*80*2 / 4
		mov rsi, rdi
		mov rdi, TTY_TEXT_VIDEO_OFFSET

	.loop:
		lodsd
		stosd
		dec edx
		jnz .loop

		ret
	endproc

	;! Set the cursor position
	;: Int x -> Int y -> IO ()
	;- rax, rdx, rdi, rsi
	proc 0, set_cursor
		assert rdi, ge, 0, "set_cursor: X is negative!"
		assert rsi, ge, 0, "set_cursor: Y is negative!"
		assert rdi, le, 80, "set_cursor: X more than 80!"
		assert rsi, le, 25, "set_cursor: Y more than 25!"

		shl rsi, 4
		add rdi, rsi
		shl rsi, 2
		add rdi, rsi ; rdi = x + y*80

		mov dx, 3D4h
		mov al, 0Fh ; Write low cursor position
		out dx, al
		inc dx
		mov al, dil
		out dx, al ; Out

		shr edi, 8 ; Switch to high

		dec dx
		mov al, 0Eh ; Write high cursor position
		out dx, al
		inc dx
		mov al, dil
		out dx, al ; Out

		ret
	endproc

	;: TTYLine :: *Mem

	;! Scroll the screen up
	;: Line | () -> Bool keep line? -> Line | ()
	proc 0, scroll_up
		; TODO
	endproc

	;! Scroll the screen down
	;: Line | () -> Bool keep line? -> Line | ()
	proc 0, scroll_down
		; TODO
	endproc
endclass
; vim: ts=8 sw=8 syn=fasm
