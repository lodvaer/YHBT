;; Quaject related functionality, such as create, remove, etc.

class q
	ivar base, Q_TABLE
	;! Create a new quaject
	;: *Mem base -> Int realsize -> *Q
	;. mm.palloc, mm.pclear, memcpy
	;+ rdi, rsi
	proc 0, create
		push rdi, rsi
		mov edi, 1000h
		lock xadd [this.base], rdi
		push rdi
		xor rsi, rsi
		call mm.palloc

		pop rdi
		call mm.pclear

		mov rax, rdi
		pop rsi, rdx
		tailcall memcpy
	endproc

	;! Clone a quaject
	;: *Q a -> ():():*Q a:*Q a
	;. mm.palloc, mm.pcopy
	; rdi = Cloned
	; rsi = Original
	proc 0, clone
		push rdi
		mov rdi, 1000h
		lock xadd [this.base], rdi
		push rdi
		xor rsi, rsi
		call mm.palloc

		pop rdi
		pop rsi
		tailcall mm.pcopy
	endproc
endclass

; vim: ts=8 sw=8 syn=fasm
