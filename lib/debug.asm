; Shared strings:
debug_arrow:
	db " -> ", 0
debug_ground:
	db "|", 10, 0
debug_joiner:
	db ":", 0



;! Print the taken pages in a page table.
;: *PageTable -> Int level -> IO ()
; Quick and dirty.
debug_print_ptable:
	push rbx, r15, r14, r13
	mov r13, rsi
	lea r14, [.table]

	cmp rdi, 0
	jne .got_it
	mov rdi, cr3
.got_it:
	mov r15, IDENT_MAP
	add r15, rdi
	mov rbx, 0x1000 / 16
	lea r14, [.table]

	cmp r13, 0
	jne .loop
	shr rbx, 1 ; Or the identity-mapping floods us.
	add rbx, 10h
.loop:
	bt  qword [r15], 0
	jnc .over

	mov rdi, [r14 + r13*8]
	call kputs

	mov rdi, r15
	call kprinthex

	lea rdi, [debug_joiner]
	call kputs

	mov rdi, [r15]
	call kprinthex

	lea rdi, [debug_ground]
	call kputs

	cmp r13, 3
	je .over

	mov rdi, [r15]

	cmp r13, 2
	jne .skipcheck

	test rdi, PDE.PS
	jnz .over
.skipcheck:
	and rdi, not 7FFh

	mov rsi, r13
	inc rsi
	call debug_print_ptable

.over:
	add r15, 16
	dec rbx
	jnz .loop

	pop rbx, r15, r14, r13
	ret

.debug_pml4: db "PML4E: ", 0
.debug_pdp:  db "    PDPE: ", 0
.debug_pd:   db "        PDE: ", 0
.debug_pt:   db "            PTE: ", 0
.debug_p:    db "                PE: ", 0

.table:
	dq .debug_pml4 + IDENT_MAP
	dq .debug_pdp  + IDENT_MAP
	dq .debug_pd   + IDENT_MAP
	dq .debug_pt   + IDENT_MAP
	dq .debug_p    + IDENT_MAP

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
	push rbx, r15
	mov rbx, [malloc.base]
	xor r8, r8

	lea rdi, [.header]
	call kputs
	mov rdi, rbx
	call kprinthex
.loop:
	lea rdi, [debug_arrow]
	call kputs

	mov r15, [rbx + r8]
	mov rdi, r15
	call kprintaddr
	btr r15, 63
	add r8, r15
	add r8, 8

	test r15, r15
	jz .phail

	cmp r8, [malloc.max]
	jnae .loop
.phail:
	lea rdi, [debug_arrow]
	call kputs
	lea rdi, [debug_ground]
	call kputs

	pop rbx, r15
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
