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
macro retj c, landing
{
	j#c landing
}

macro retc     {  retj c,    null }
macro reto     {  retj o,    null }
macro retz     {  retj z,    null }
macro retp     {  retj p,    null }
macro rete     {  retj e,    null }
macro reta     {  retj a,    null }
macro retg     {  retj g,    null }
macro retb     {  retj b,    null }
macro retl     {  retj l,    null }

macro retae    {  retj ae,   null }
macro retge    {  retj ge,   null }
macro retbe    {  retj be,   null }
macro retle    {  retj le,   null }

macro retnc    {  retj nc,   null }
macro retno    {  retj no,   null }
macro retnz    {  retj nz,   null }
macro retnp    {  retj np,   null }
macro retne    {  retj ne,   null }
macro retna    {  retj na,   null }
macro retng    {  retj ng,   null }
macro retnb    {  retj nb,   null }
macro retnl    {  retj nl,   null }

macro retnae   {  retj nae,  null }
macro retnge   {  retj nge,  null }
macro retnbe   {  retj nbe,  null }
macro retnle   {  retj nle,  null }

macro retz     {  retj z,    null }
macro retnz    {  retj nz,   null }

macro retcxz   {  retj cxz,  null }
macro retecxz  {  retj ecxz, null }
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
; }}}
; {{{ General macro utility
macro append whut, what
{
	match any, whut \{ whut equ whut, what \}
	match , whut    \{ whut equ what       \}
}
; }}}
; {{{ Proc macro

; Interrupt proc
macro intproc name, [remaps]
{
	; Don't assume we have a working stack.
	common
		CALLTRACE equ N
		proc 0, name, remaps
		restore CALLTRACE
}
; Normal proc

macro proc stackspace, name, [remaps]
{
	common
		label name
		match =N, CALLTRACE \{
			if stackspace < 0
				; Forced entry
				push rbp
				mov rbp, rsp
			else if stackspace > 0
				push rbp
				mov rbp, rsp
				sub rsp, stackspace*8
			end if
			macro ret \\{
				if stackspace <> 0
					leave
				end if
				ret
			\\}
			macro tailcall addr \\{
				if stackspace <> 0
					leave
				end if
				jmp addr
			\\}
			macro retj c, landing \\{
				if stackspace <> 0
					j\\#c leave.\\#landing
				else
					j\\#c landing
				end if
			\\}
		\}
		match =Y, CALLTRACE \{
			push rbp
			mov rbp, rsp
			if stackspace > 0
				sub rsp, stackspace*8
			end if
			macro ret \\{
				leave
				ret
			\\}
			macro tailcall addr \\{
				call addr
				ret
			\\}
			macro retj c, landing \\{
				j\\#c leaving.\\#landing
			\\}
		\}
		local to_restore
		to_restore equ
		macro _remap reg, re \{
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
		macro remap [rem] \{
		\forward match reg->re, rem \\{
				_remap reg, re
			\\}
		\}
	forward
		match reg->re, remaps \{
			_remap reg, re
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
			purge endproc, remap, _remap, ret, tailcall, retj
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
macro var_lock naem {
	match =N, CFG_UNSAFE \{
		match =Y, CFG_SMP \\{
			var_helper 8, naem, value
		\\}
		match =N, CFG_SMP \\{
			var_helper 4, naem, value
		\\}
	\}
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
macro ivar_align size {
	common
		local ivar_macro
		append TO_IVAR, ivar_macro
		macro ivar_macro \{
			align size
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
macro ivar_lock naem {
	match =N, CFG_UNSAFE \{
		match =Y, CFG_SMP \\{
			ivar_helper 8, naem, 0
		\\}
		match =N, CFG_SMP \\{
			ivar_helper 4, naem, 0
		\\}
	\}
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

	
	irp sak, varq, vard, varw, varb, var, var_lock \{
		macro sak naem \\{
			common
				append to_restore, \\this\\#\\.\\#\\naem
				\\this\\#\\.\\#\naem equ name\\#\\.\\#\\naem
				sak name\\#\\.\\#\\naem
		\\}
	\}
	irp sak, ivarq, ivard, ivarw, ivarb, ivar, ivar_lock \{
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
	macro proc stackspace, naem, [args]
	\{
		\common
			append to_restore, \this\#\.\#\naem
			\this\#\.\#\naem equ name\#\.\#\naem
			proc stackspace, name\#\.\#\naem, args
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
		purge varq, vard, varw, varb, var, var_lock
		purge ivarq, ivard, ivarw, ivarb, ivar, ivar_lock
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
	label name#.start
	offset = 0
	to_restore equ 
	macro var [naem]
	\{
		forward
			label name\#\.\#\naem at ende + offset
			append to_restore, \this\#\.\#\naem
			\this\#\.\#\naem equ name\#\.\#\naem
			offset = offset + 8
	\}
	macro proc stackspace, naem, [args]
	\{
		\common
			append to_restore, \this\#\.\#\naem
			\this\#\.\#\naem equ name\#\.\#\naem
			proc stackspace, name\#\.\#\naem, args
	\}
	macro endquaject
	\{
		local I, sak
		align 8
		ende = $
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
	pusha
forward
	if string in <rax,rbx,rcx,rdx,rdi,rsi,rsp,rbp,r8,r9,r10,r11,r12,r13,r14,r15>
		mov rdi, string
		call kprinthex
		popa
		pusha
	else
		local .sak, .over
		lea rdi, [.sak]
		call kputs
		popa
		pusha
		jmp .over
	.sak:	db string, 0
	.over:
	end if
common
	lea rdi, [debug_newline]
	call kputs
	popa
}

macro _printreg [reg]
{
	local .str, .over, .str2
common
	pusha
reverse
	push reg
forward
	jmp .over
.str:	db `reg, ": ", 0
.str2:	db 10, 0
.over:
	lea rdi, [.str]
	call kputs
	pop rdi
	call kprinthex
	lea rdi, [.str2]
	call kputs
common
	popa

}

; }}}
; {{{ Synchronization

macro spinlock i, place, _reg1, _reg2
{
	local reg1, reg2
	match any, _reg1 \{
		reg1 equ _reg1
	\}
	match any, _reg2 \{
		reg2 equ _reg2
	\}
	match , _reg1 \{
		reg1 equ a
	\}
	match , _reg2 \{
		reg2 equ d
	\}
	match =N, CFG_UNSAFE \{
		match =saveto->reg, i \\{
			pushfq
			pop reg
			cli
		\\}
		match =save, i \\{
			pushfq
			match r1=,r2, reg1,reg2 \\\{
				pop r\\\#r1\\\#x
				mov [place], e\\\#r1\\\#x
			\\\}
			cli
		\\}
		match =nosave, i \\{
			cli
		\\}
		; TODO: Check if this actually works.
		; (Which registers to use is mostly OK, though)
		match =Y, CFG_SMP \\{
			match r1=,r2, reg1,reg2 \\\{
				local .over, .back
				mov e\\\#r1\\\#x, 10000h
				lock xadd [place+4], e\\\#r1\\\#x
				mov e\\\#r2\\\#x, e\\\#r1\\\#x
				shr e\\\#r2\\\#x, 10h
				cmp r1\\\#x, r2\\\#x
				xchg bx, bx
				je .over
			.back:	pause
				mov e\\\#r1\\\#x, [place+4]
				cmp r1\\\#x, r2\\\#x
				jne .back
			.over:
			\\\}
		\\}
	\}
}
macro spinunlock i, place
{
	match =N, CFG_UNSAFE \{
		local .over
		match =saveto->reg, i \\{
			bt reg, 9
			jnc .over
			sti
		.over:
		\\}
		match =save, i \\{
			mov eax, [place]
			bt eax, 9
			jnc .over
			sti
		.over:
		\\}
		match =nosave, i \\{
			sti
		\\}
		match =Y, CFG_SMP \\{
			inc word [place+4]
		\\}
	\}
}
; }}}
; vim: ts=8 sw=8 syn=fasm
