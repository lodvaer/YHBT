macro assert_h method, reg, cond, to, mesg
{
if ASSERT
	local .failmsg, .over, .next
	method reg, to
	j#cond .over
	
	xchg bx, bx
	call .next
.next:	pop rdi
	call kprintaddr
	lea rdi, [.failmsg]
	call kputs
	jmp panic
.failmsg:
	db ": "
	db mesg, 10, 0
.over:
end if
}
macro assert reg, cond, to, mesg
{
	assert_h cmp, reg, cond, to, mesg
}
macro assert_t reg, cond, to, mesg
{
	assert_h test, reg, cond, to, mesg
}

; vim: ts=8 sw=8 syn=fasm
