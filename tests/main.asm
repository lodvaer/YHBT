;! Test framework

jmp tests.over
tests.torun equ

class tests
	include 'malloc.asm'
endclass

tests.over:
match I, tests.torun {
	irp P, I {
		call P
	}
}
	_puts "AOK."
	die

; vim: ts=8 sw=8 syn=fasm