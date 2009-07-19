; HIC SVNT LEONES

; {{{ ASM extensions
macro push [arg]
{
	forward	push arg
}
macro pop [arg]
{
	reverse pop arg
}
macro pusha
{
	push rax, rbx, rcx, rdx, rdi, rsi, r8, r9, r10, r11, r12, r13, r14, r15
}
macro popa
{
	pop rax, rbx, rcx, rdx, rdi, rsi, r8, r9, r10, r11, r12, r13, r14, r15
}
PUSHA_DISTANCE = 14*8
macro die
{
	xchg bx, bx
@@:	hlt
	rep nop
	jmp @b
}
d1 equ db
d2 equ dw
d4 equ dd
d8 equ dq
; Null is in kernel/misc.asm
; {{{ retcc -> jcc null
retc   equ jc   null
reto   equ jo   null
retz   equ jz   null
retp   equ jp   null
rete   equ je   null
reta   equ ja   null
retg   equ jg   null
retb   equ jb   null
retl   equ jl   null

retae  equ jae  null
retge  equ jge  null
retbe  equ jbe  null
retle  equ jle  null

retnc   equ jnc   null
retno   equ jno   null
retnz   equ jnz   null
retnp   equ jnp   null
retne   equ jne   null
retna   equ jna   null
retng   equ jng   null
retnb   equ jnb   null
retnl   equ jnl   null

retnae equ jnae null
retnge equ jnge null
retnbe equ jnbe null
retnle equ jnle null

retz   equ jz  null
retnz  equ jnz null

retcxz equ jcxz null
retecxz equ jecxz null
; }}}
; }}}
; {{{ Vectors and descriptors
macro system_segment_desc base, limit, flags
{
	dq ((base and 0FF000000h) shl 20h) or ((limit and 0FF0000h) shl 20h) or (flags shl 20h) or \
	   ((base and 0FF0000h) shl 10h) or ((base and 0FFFFh) shl 10h) or (limit and 0FFFFh)
	dq (base shr 20h)
}
macro intvector_setregs where, selector, flags
{
	mov rax, ((where and 0FFFF0000h) shl 20h) or (flags shl 20h) or (selector shl 10h) or (where and 0FFFFh)
	mov rbx, where shr 20h
}
macro intvector_set where, selector, flags, vector
{
	if vector < 0
		display "Vector < 0: "
		offsetdisp
	end if
	intvector_setregs where, selector, flags
	mov qword [(vector * 16)], rax
	mov qword [(vector * 16 + 8)], rbx
}
; }}}
; {{{ Debugging
macro symbdisp symb
{
	bits = 64
	display `symb, ": 0"
	repeat bits/4
		d = '0' + symb shr (bits - %*4) and 0Fh
		if d > '9'
			d = d + 'A' - '9' - 1
		end if
		display d
	end repeat
	display "h", 10
}
macro offsetdisp
{
	bits = 16
	display 'Offset 0'
	repeat bits/4
		d = '0' + $ shr (bits-%*4) and 0Fh
		if d > '9'
			d = d + 'A'-'9'-1
		end if
		display d
	end repeat
	display "h", 10
}
CALLTRACE_ACTIVE = 0
macro call symb ; TODO: SMP?
{
if CALLTRACE_ACTIVE
	local .lbl, .over, .it
	push rax, rdi, rsi
	mov rdi, 10h
	call malloc
	mov rdi, symb
	mov [rax], rdi
	mov rdi, [calltrace_head]
	mov [rax + 8], rdi
	mov [calltrace_head], rax
	pop rax, rdi, rsi
end if
	call symb
if CALLTRACE_ACTIVE
	push rdi, rsi
	mov rdi, [calltrace_head]
	mov rsi, [rdi + 8]
	mov [calltrace_head], rsi
	call free
	pop rdi, rsi
end if
}
; }}}
; {{{ General macro utility
macro append whut, what
{
	match any, whut \{ whut equ whut, what \}
	match , whut    \{ whut equ what       \}
}
; }}}
; {{{ Proc macro
macro proc name, [remaps]
{
	common
		label name
		local to_restore, remap
		to_restore equ
		macro remap reg, re \{
			\local prg
			prg equ
			irp tst, a,b,c,d \\{
				match =tst, reg \\\{
					append prg, r\#re
					r\#re    equ r\#reg\#x
					append prg, r\#re\#d
					r\#re\#d equ e\#reg\#x
					append prg, r\#re\#w
					r\#re\#w equ reg\#x
					append prg, r\#re\#b
					r\#re\#b equ reg\#l
					append prg, r\#re\#h
					r\#re\#h equ reg\#h
				\\\}
			\\}
			irp tst, di,si,sp,bp \\{
				match =tst, reg \\\{
					append prg, r\#re
					r\#re    equ r\#reg
					append prg, r\#re\#d
					r\#re\#d equ e\#reg
					append prg, r\#re\#w
					r\#re\#w equ reg
					append prg, r\#re\#b
					r\#re\#b equ reg\#l
				\\\}
			\\}
			irp tst, 8,9,10,11,12,13,14,15 \\{
				match =tst, reg \\\{
					append prg, r\#re
					r\#re    equ r\#reg
					append prg, r\#re\#d
					r\#re\#d equ r\#reg\#d
					append prg, r\#re\#w
					r\#re\#w equ r\#reg\#w
					append prg, r\#re\#b
					r\#re\#b equ r\#reg\#b
				\\\}
			\\}
			append to_restore, prg
		\}
	forward
		match reg->re, remaps \{
			remap reg, re
		\}
	common
		if ~ used name
			display "WARN: Proc " # `name # \
				" is defined but not used.", 10
		end if
		;if used name
		macro endproc
		\{
		;	end if
			\local I, top
			match I, to_restore \\{
				irp top, I \\\{
					restore top
				\\\}
			\\}
			purge endproc
		\}
	
}
; }}}
; {{{ Vars
macro var_helper size, [naem]
{
	forward
		if (var_offset and (size - 1)) ; Align
			var_offset = var_offset + size - \
				     (var_offset and (size - 1))
		end if
		naem = _VARS + var_offset ; Define
		var_offset = var_offset + size ; Make room
}
macro varq [naem] {
	common var_helper 8, naem
}
macro vard [naem] {
	common var_helper 4, naem
}
macro varw [naem] {
	common var_helper 2, naem
}
macro varb [naem] {
	common var_helper 1, naem
}
macro var [naem] {
	common var_helper 8, naem
}
macro ivar_helper size, naem, [value]
{
	common
		local ivar_macro
		append TO_IVAR, ivar_macro
		macro ivar_macro
		\{
			align size
			label naem
			d \# size value
		\}
}
macro ivarq naem, [value] {
	common ivar_helper 8, naem, value
}
macro ivard naem, [value] {
	common ivar_helper 4, naem, value
}
macro ivarw naem, [value] {
	common ivar_helper 2, naem, value
}
macro ivarb naem, [value] {
	common ivar_helper 1, naem, value
}
macro ivar naem, [value] {
	common ivar_helper 8, naem, value
}
; }}}
; {{{ Class macro
var_offset = 0
macro class name
{
	label name
	local to_restore, to_purge
	to_restore equ
	to_purge equ
	this equ name

	
	irp sak, varq, vard, varw, varb, var \{
		macro sak naem \\{
			common
				append to_restore, \\this\\#\\.\\#\\naem
				\\this\\#\\.\\#\naem equ name\\#\\.\\#\\naem
				sak name\\#\\.\\#\\naem
		\\}
	\}
	irp sak, ivarq, ivard, ivarw, ivarb, ivar \{
		macro sak naem, [value]\\{
			common
				append to_restore, \\this\\#\\.\\#\\naem
				\\this\\#\\.\\#\\naem equ name\\#\\.\\#\\naem
				sak name\\#\\.\\#\\naem, value
		\\}
	\}
	macro const naem, val
	\{
		append to_restore, \this\#\.\#\naem
		\this\#\.\#naem equ name\#\.\#\naem
		name\#\.\#\naem = val
	\}
	macro proc naem, [args]
	\{
		\common
			append to_restore, \this\#\.\#\naem
			\this\#\.\#\naem equ name\#\.\#\naem
			proc name\#\.\#\naem, args
	\}
	macro endclass
	\{
		local I, sak
		name\#\.\#\size = $ - name
		restore this, var
		purge proc, endclass
		match I, to_restore \\{
			irp sak, I \\\{
				restore sak
			\\\}
		\\}
		purge varq, vard, varw, varb, var
		purge ivarq, ivard, ivarw, ivarb, ivar
	\}

}
; }}}
; {{{ Quaject macro
macro quaject name
{
	local ende, offset, to_restore
	align 8
	label name
	this equ name
	org 0
	offset = 0
	to_restore equ 
	macro var [naem]
	\{
		forward naem
			label name\#\.\#\naem at ende + offset
			append to_restore, \this\#\.\#\naem
			\this\#\.\#\naem equ name\#\.\#\naem
			offset = offset + 8
	\}
	macro proc naem, [args]
	\{
		\common
			append to_restore, \this\#\.\#\naem
			\this\#\.\#\naem equ name\#\.\#\naem
			proc name\#\.\#\naem, args
	\}
	macro endquaject
	\{
		local I, sak
		align 8
		if $ and 3Fh
			ende = $ or 3Fh + 1
		else
			ende = $
		end if
		restore this
		purge proc, var, endquaject
		match I, to_restore \\{
			irp sak, I \\\{
				restore sak
			\\\}
		\\}
		name#.size = ende + offset
		name#.realsize = ende
		\\org name + name#.realsize
	\}

}
; }}}
; {{{ Other utility
macro _puts [string]
{
common
	local .sak, .over
	push rax, rdi, rsi, r10
	lea rdi, [.sak]
	call kputs
	pop rax, rdi, rsi, r10
	jmp .over
.sak:
forward
	db string
common
	db 10, 0
.over:
}

; }}}
; vim: ts=8 sw=8 syn=fasm
