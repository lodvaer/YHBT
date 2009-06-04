macro assert reg, cond, to, mesg
{
if ASSERT
	local .failmsg, .over, .next
	cmp reg, to
	j#cond .over
	
	xchg bx, bx
	call .next
.next:	pop rdi
	call kprintaddr
	lea rdi, [.failmsg]
	call kputs
	die
.failmsg:
	db ": "
	db mesg, 0
.over:
end if
}

; vim: ts=8 sw=8 syn=fasm
