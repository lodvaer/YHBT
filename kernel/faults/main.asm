; The faults and their handlers.

the_faults fix divide, debug, nmi, breakpoint, overflow, boundscheck,\
	  invalid_opcode, cocpu_unavail, doublefault, cocpu_overrun,  \
	  invalid_tss, segfault, stack, genprot, pagefault, reserved,  \
	  cocpu_error, alignment_check, machine_check, simd_fpu,        \
	  reserved2,  reserved3,  reserved4,  reserved5,  reserved6,     \
	  reserved7, reserved8, reserved9, reservedA, reservedB,          \
	  security, reservedC

fault_has_error fix doublefault, invalid_tss, segfault, stack, genprot,\
               pagefault, alignment_check
append TO_INIT_64, faults.init
macro faults.init {
	local i
	i = 0
	irp fault, the_faults \{
		intvector_set (faults.\#\fault + HIGH_HALF), SEL_LONG, 8F00h, i
		i = i + 1
	\}
}
macro default_fault_proc name
{
	proc name
	if name in <fault_has_error>
	else
		push 0
	end if
	push rdi
	lea rdi, [.msg]
	jmp this.default_action
}
class faults
	proc default_action	
		pusha ; Pusha moves the stack 16*8 down.
		call kputs ; Message

		lea rdi, [.cr2]
		call kputs
		mov rdi, cr2
		call kprinthex

		lea rdi, [.error]
		call kputs
		mov rdi, [rsp + 15*8]
		call kprinthex

		lea rdi, [.rip]
		call kputs
		mov rdi, [rsp + 16*8]
		call kprinthex
	
		lea rdi, [.nl]
		call kputs

		; Because we are irresponsible bastards, we just die.
		jmp panic

		popa
		pop rdi
		add rsp, 8 ; Remove error code
		iretq
	.cr2:	db     "cr2:     ", 0
	.error:	db 10, "error:   ", 0
	.rip:	db 10, "ret rip: ", 0
	.nl:	db 10, 0

	endproc

	default_fault_proc divide
	.msg:
		db "00#DE: Division by zero error.", 10, 0
	endproc

	default_fault_proc debug
	.msg:
		db "01#DB: Debug exception.", 10, 0
	endproc

	default_fault_proc nmi
	.msg:
		db "02#NMI: Non-maskable interrupt.", 10, 0
	endproc

	default_fault_proc breakpoint
	.msg:
		db "03#BP: Breakpoint.", 10, 0
	endproc
	default_fault_proc overflow
	.msg:
		db "04#OF: Overflow.", 10, 0
	endproc

	default_fault_proc boundscheck
	.msg:
		db "05#BR: Bound range exceeded.", 10, 0
	endproc

	default_fault_proc invalid_opcode
	.msg:
		db "06#UD: Invalid opcode.", 10, 0
	endproc

	default_fault_proc cocpu_unavail
	.msg:
		db "07#NM: Coprocessor not available.", 10, 0
	endproc

	default_fault_proc doublefault
	.msg:
		db "08#NM: Double fault.", 10, 0
	endproc

	default_fault_proc cocpu_overrun
	.msg:
		db "09: Coprocessor segment overrun.", 10, 0
	endproc

	default_fault_proc invalid_tss
	.msg:
		db "0A#TS: Invalid TSS.", 10, 0
	endproc

	default_fault_proc segfault
	.msg: 
		db "0B#NP: Segment not present.", 10, 0
	endproc

	default_fault_proc stack
	.msg:
		db "0C#SS: Stack exception.", 10, 0
	endproc

	default_fault_proc  genprot
	.msg:
		db "0D#GP: General Protection Fault.", 10, 0
	endproc

	default_fault_proc pagefault
	; http://linux-security.com.cn/ebooks/ulk3-html/0596005652/understandlk-CHP-9-SECT-4.html
	.msg:
		db "0E#PF: Page fault.", 10, 0
	endproc

	default_fault_proc reserved
	.msg:
		db "0F: Reserved.", 10, 0
	endproc

	default_fault_proc cocpu_error
	.msg:
		db "10#MF: Coprocessor error.", 10, 0
	endproc

	default_fault_proc alignment_check
	.msg:
		db "11#AC: Alignment check.", 10, 0
	endproc

	default_fault_proc machine_check
	.msg:
		db "12#MC: Machine check.", 10, 0
	endproc

	default_fault_proc simd_fpu
	.msg:
		db "13#XM/#XF: SIMD Floating-point exception.", 10, 0
	endproc

	default_fault_proc reserved2
	.msg:
		db "14: Reserved.", 10, 0
	endproc

	default_fault_proc reserved3
	.msg:
		db "15: Reserved.", 10, 0
	endproc

	default_fault_proc reserved4
	.msg:
		db "16: Reserved.", 10, 0
	endproc

	default_fault_proc reserved5
	.msg:
		db "17: Reserved.", 10, 0
	endproc

	default_fault_proc reserved6
	.msg:
		db "18: Reserved.", 10, 0
	endproc

	default_fault_proc reserved7
	.msg:
		db "19: Reserved.", 10, 0
	endproc

	default_fault_proc reserved8
	.msg:
		db "1A: Reserved.", 10, 0
	endproc

	default_fault_proc reserved9
	.msg:
		db "1B: Reserved.", 10, 0
	endproc

	default_fault_proc reservedA
	.msg:
		db "1C: Reserved.", 10, 0
	endproc

	default_fault_proc reservedB
	.msg:
		db "1D: Reserved.", 10, 0
	endproc

	default_fault_proc security
	.msg:
		db "1E#SX: Security exception", 10, 0
	endproc

	default_fault_proc reservedC
	.msg:
		db "1F: Reserved.", 10, 0
	endproc
endclass

; vim: ts=8 sw=8 syn=fasm
