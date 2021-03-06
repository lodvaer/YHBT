;; Test framework

jmp tests.over
tests.torun equ

;! The tests.
class tests
	include 'malloc.asm'
	include 'rbtree.asm'
	include 'mvar.asm'
	include 'queue.asm'
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
