; Shared strings:
debug_arrow:
	db " -> ", 0
debug_back_arrow:
	db " <- ", 0
debug_ground:
	db "|", 10, 0
debug_joiner:
	db ":", 0
debug_newline:
	db 10, 0


;! Print an MVar
;: MVar a -> IO ()
debug_print_mvar:
	push rbx
	mov rbx, rdi
	_puts "MVar:"
	mov rdi, [rbx + mvar.SPINLOCK]
	call kprinthex
	lea rdi, [debug_newline]
	call kputs
	mov rdi, [rbx + mvar.CONTENT]
	call kprinthex
	lea rdi, [debug_newline]
	call kputs
	mov rdi, [rbx + mvar.QUEUE_STATUS]
	call kprinthex
	lea rdi, [debug_newline]
	call kputs
	mov rdi, [rbx + mvar.QUEUE_HEAD]
	call kprinthex
	lea rdi, [debug_newline]
	call kputs
	mov rdi, [rbx + mvar.QUEUE_TAIL]
	call kprinthex
	_puts 10, "MVar reschedule queue:"
	mov rdi, [rbx + mvar.QUEUE_HEAD]
	call debug_print_ll
	mov rdi, rbx
	pop rbx
	ret


;! Print the pqueue
debug_print_pqueue:
	_puts "PQueue:"
	push rbx, r15
	mov ecx, MSR.KGS
	rdmsr
	shl rdx, 32
	mov ebx, eax
	or  rbx, rdx

	mov r15, rbx
.back:
	mov rdi, [r15 + q_thread.prev]
	call kprinthex
	lea rdi, [debug_back_arrow]
	call kputs
	mov rdi, r15
	call kprinthex
	lea rdi, [debug_arrow]
	call kputs
	mov rdi, [r15 + q_thread.next]
	call kprinthex
	lea rdi, [debug_newline]
	call kputs
	mov r15, [r15 + q_thread.next]
	cmp r15, rbx
	jne .back
	pop rbx, r15
	ret
	
;! Print a thread
debug_print_thread:
	push rbx
	test rdi, rdi
	jnz .over
	
	mov ecx, MSR.KGS
	rdmsr
	shl rdx, 32
	mov edi, eax
	or  rdi, rdx
.over:
	mov rbx, rdi
	lea rdi, [.h]
	call kputs
	mov rdi, rbx
	call kprinthex

	lea rdi, [.next]
	call kputs
	mov rdi, [rbx + q_thread.next]
	call kprinthex
	lea rdi, [.prev]
	call kputs
	mov rdi, [rbx + q_thread.prev]
	call kprinthex

	lea rdi, [.rip]
	call kputs
	mov rdi, [rbx + q_thread.rip]
	call kprinthex
	lea rdi, [.rsp]
	call kputs
	mov rdi, [rbx + q_thread.rsp]
	call kprinthex
	
	lea rdi, [.pid]
	call kputs
	mov rdi, [rbx + q_thread.pid]
	call kprinthex
	lea rdi, [.tid]
	call kputs
	mov rdi, [rbx + q_thread.tid]
	call kprinthex

	lea rdi, [.fds]
	call kputs
	lea rdi, [rbx + q_thread.fds]
	call debug_print_rbtree

	pop rbx
	ret
.h:	db "q_thread ", 0
.next:	db 10, "next: ", 0
.prev:	db ", prev: ", 0
.rip:	db 10, "rip:  ", 0
.rsp:	db ", rsp:  ", 0
.pid:	db 10, "pid:  ", 0
.tid:	db ", tid:  ", 0
.fds:	db 10, "file descriptors:", 10, 0




;! Print an RBTree
;: RBTree -> IO ()
debug_print_rbtree:
	_puts "RBTree:"
	xor rsi, rsi
	mov rdi, [rdi + rbtree.TREE]
	cmp rdi, 0
	jne .rbnode
	lea rdi, [.null]
	call kputs
	ret
	; rdi = RBNode
	; rsi = indentLevel
.rbnode:
	push rbx, r15, r14
	mov rbx, rdi
	mov r15, rsi

	test rbx, rbx
	jz .print_null

		mov rdi, rbx
		call kprinthex

		lea rdi, [debug_joiner]
		call kputs

		mov rdi, [rbx + rbtree.KEY]
		call kprinthex

		lea rdi, [debug_joiner]
		call kputs

		mov rdi, [rbx + rbtree.PARENT]
		test rdi, 1
		jz .red
		.black:
			lea rdi, [.s_black]
			call kputs
			jmp @f
		.red:
			lea rdi, [.s_red]
			call kputs
			jmp @f

	.print_null:
		lea rdi, [.null]
		call kputs
	@@:

	lea rdi, [debug_newline]
	call kputs

	test rbx, rbx
	jz .ret

	mov rdi, [rbx + rbtree.RIGHT]
	test rdi, rdi
	jz @f

	call .indent
	lea rdi, [.right]
	call kputs
	mov rdi, [rbx + rbtree.RIGHT]
	mov rsi, r15
	add rsi, 4
	call .rbnode
@@:

	mov rdi, [rbx + rbtree.LEFT]
	test rdi, rdi
	jz @f
	call .indent

	lea rdi, [.left]
	call kputs
	mov rdi, [rbx + rbtree.LEFT]
	mov rsi, r15
	add rsi, 4
	call .rbnode
@@:
.ret:
	pop rbx, r15, r14
	ret

.indent:
	mov r14, r15
	test r15, r15
	retz
@@:	lea rdi, [.space]
	call kputs
	dec r15
	jnz @b
	mov r15, r14
	ret

.right:		db "R: ", 0
.left:		db "L: ", 0
.null:		db "NULL", 0
.space:		db " ", 0
.s_red:		db "Red", 0
.s_black:	db "Black", 0

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
;. debug_print_ll
debug_print_alarms:
	_puts 10, "Alarms:"
	mov rdi, [alarm.list]

;! Print a linked list with 3 elements, skipping the 3rd.
;: [a:b:c] -> IO ()
;. kprinthex, kputs
debug_print_ll3:
	push rbx
	mov rbx, rdi
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
;! Print
debug_print_ll:
	push rbx
	mov rbx, rdi
.loop:
	cmp rbx, 0
	je .ground
	
	mov rdi, [rbx]
	call kprinthex

	lea rdi, [debug_arrow]
	call kputs

	mov rbx, [rbx + 8h]
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


match =Y, CALLTRACE {

debug_print_calltrace:
	push r15

	lea rdi, [.header]
	call kputs

	mov r15, rbp
	test r15, r15
	jz .done
.loop:
	mov rdi, [r15 + 8]
	call kprintaddr
	lea rdi, [debug_newline]
	call kputs
	mov r15, [r15]
	test r15, r15
	jnz .loop
.done:
	pop r15
	ret

	var calltrace_head
;debug_print_calltrace:
	push r15
	lea rdi, [.header]
	call kputs

	mov r15, [calltrace_head]
	cmp r15, 0
	je .over

;.loop:
	mov rdi, [r15]
	call kprintaddr
	mov r15, [r15 + 8]
	lea rdi, [debug_newline]
	call kputs
	cmp r15, 0
	jne .loop
.over:
	pop r15
	ret

.header:
	db "Calltrace: ", 10, 0

}
match =N, CALLTRACE {
	debug_print_calltrace = null
}

; vim: ts=8 sw=8 syn=fasm
