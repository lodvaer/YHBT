; Shared strings:
debug_arrow:
	db " -> ", 0
debug_ground:
	db "|", 10, 0
debug_joiner:
	db ":", 0

;! Print the current alarms
;: IO ()
;. kprinthet, kputs
debug_print_alarms:
	push rbx
	mov rbx, [alarm.list]
.loop:
	cmp rbx, 0
	je .ground
	
	mov rdi, [rbx]
	call kprinthex

	lea rdi, [debug_joiner]
	call kputs

	mov rdi, [rbx + 8]
	call kprinthex

	lea rdi, [debug_arrow]
	call kputs

	mov rbx, [rbx + 18h]
	jmp .loop
	

.ground:
	lea rdi, [debug_ground]
	call kputs
	pop rbx
	ret

;! Print a segment of memory
;: *Mem what -> Int length -> IO ()
;. kprinthex, kputs
debug_print_mem:
	mov r8, rdi
	mov r9, rsi
	lea rdi, [.header]
	call kputs

	cmp r9, 0
	je .out
.loop:
	mov rdi, [r8]
	call kprinthex
	lea rdi, [debug_joiner]
	call kputs
	mov rdi, [r8 + 8]
	call kprinthex
	lea rdi, [debug_joiner]
	call kputs
	mov rdi, [r8 + 10h]
	call kprinthex
	lea rdi, [debug_joiner]
	call kputs
	mov rdi, [r8 + 18h]
	call kprinthex
	lea rdi, [debug_ground]
	call kputs
	add r8, 20h
	dec r9
	jnz .loop
.out:
	ret
.header:
	db "Mem: ", 10, 0

;! Print the current memory allocations
;- r8, rdi, rsi, rdx
;. kprinthex, kputs
debug_print_mallocs:
	push rbx
	mov rbx, [malloc.base]
	xor r8, r8

	lea rdi, [.header]
	call kputs
	mov rdi, rbx
	call kprinthex
	lea rdi, [debug_arrow]
	call kputs
.loop:
	mov rdi, [rbx + r8]
	call kprintaddr
	btr rdi, 63
	mov r11, rdi
	add r8, rdi
	add r8, 8

	lea rdi, [debug_arrow]
	call kputs

	or r11, r11
	jz .phail

	cmp r8, [malloc.max]
	jnae .loop
.phail:
	lea rdi, [debug_ground]
	call kputs

	pop rbx
	ret
.header:
	db "Mallocs: ", 10, 0


if CALLTRACE

	var calltrace_head
debug_print_calltrace:
	push r15
	lea rdi, [.header]
	call kputs

	mov r15, [calltrace_head]
	cmp r15, 0
	je .over

.loop:
	mov rdi, [r15]
	call kprintaddr
	mov r15, [r15 + 8]
	lea rdi, [debug_arrow]
	call kputs
	cmp r15, 0
	jne .loop
.over:
	lea rdi, [debug_ground]
	call kputs
	pop r15
	ret

.header:
	db "Calltrace: ", 10, 0

else
	debug_print_calltrace = null
end if

; vim: ts=8 sw=8 syn=fasm
