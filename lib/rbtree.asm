;! A red-black tree implementation.

;: RBTree A :: (*Proc callback | Null) : *RBNode A tree
;: RBColor  :: RB_RED | RB_BLACK
;: RBNode A :: (*RBNode A parent `or` RbColor) : *RBNode A left : *RBNode A right : (Int key | ? key) : A what

;TODO: Delete

class rbtree
	; Colours: (not used)
	const RED,      0h
	const BLACK,    1h
	; Offsets:
	const CALLBACK, 0h
	const TREE,     8h

	const PARENT,   0h
	const COLOUR,   0h ; The lowest bit.
	const LEFT,     8h
	const RIGHT,   10h
	const KEY,     18h
	const WHAT,    20h

	;! Create a new RBTree
	;: *Proc callback -> RBTree
	;- rdi
	;. malloc
	proc new
		push rdi
		mov rdi, 10h
		call malloc
		assert rax, ne, 0, "rbtree.new: malloc failed."
		pop rdi
		mov [rax], rdi
		mov qword [rax + this.TREE], 0
		ret
	endproc

	;! Find the first node in a RBTree
	;: RBTree A -> A:Key:RBNode A
	proc first
		mov rdi, [rdi + this.TREE]
		test rdi, rdi
		jz .fail
	.loop:
		mov rax, [rdi + this.LEFT]
		test rax, rax
		jz .ret
		mov rdi, rax
		jmp .loop
	.ret:
		mov rax, [rdi + this.WHAT]
		mov rdx, [rdi + this.KEY]
		ret
	.fail:
		mov rax, -1
		ret
	endproc

	;! Find the last node in a RBTree
	;: RBTree A -> A:Key:RBNode A
	proc last
		mov rdi, [rdi + this.TREE]
		test rdi, rdi
		jz .fail
	.loop:
		mov rax, [rdi + this.RIGHT]
		test rax, rax
		jz .ret
		mov rdi, rax
		jmp .loop
	.ret:
		mov rax, [rdi + this.WHAT]
		mov rdx, [rdi + this.KEY]
		ret
	.fail:
		mov rax, -1
		ret
	endproc
	
	;! Find the next node
	;: RBNode A -> RBNode A
	proc next
		assert rdi, ne, [rdi + this.PARENT], "rbtree.next: Incest!"
		
		mov rsi, [rdi + this.RIGHT]
		test rsi, rsi
		jz .over
	.loop:	mov rdi, rsi
		mov rsi, [rdi + this.LEFT]
		test rsi, rsi
		jnz .loop
		mov rax, rdi
		ret
	.over:
		mov rsi, [rdi + this.PARENT]
		and rsi, not 1
		test rsi, rsi
		jz  error
		cmp [rsi + this.RIGHT], rdi
		jne .ret
	.loop2:	mov rdi, rsi
		mov rsi, [rdi + this.PARENT]
		and rsi, not 1
		test rsi, rsi
		jz  error
		cmp [rsi + this.RIGHT], rdi
		je .loop2
	
	.ret:	mov rax, rsi
		ret
	endproc

	;! Insert a new item into the tree
	;: RBTree A -> (Int key | ? key) -> A -> IO ()
	proc insert
		push rdi, rsi
		mov edi, 28h
		;*+ rdx
		call malloc
		pop rdi, rsi
		mov [rax + this.KEY],  rsi
		mov [rax + this.WHAT], rdx
		mov qword [rax + this.LEFT], 0
		mov qword [rax + this.RIGHT], 0

		mov rcx, [rdi + this.TREE]
		test rcx, rcx
		jz .root
		mov rdx, [rdi + this.CALLBACK]
		test rdx, rdx
		jz .i_get
		;[TODO]
	.c_get:

	align 10h
	.i_get: ;[/TODO]
		cmp rsi, [rcx + this.KEY]
		ja .i_right
		jb .i_left
		mov rdi, rax
		call free
		mov rax, -1
		ret
	align 10h
	.i_right:
		mov rdx, [rcx + this.RIGHT]
		test rdx, rdx
		jz .ins_right
		mov rcx, rdx
		jmp .i_get
	align 10h
	.i_left:
		mov rdx, [rcx + this.LEFT]
		test rdx, rdx
		jz .ins_left
		mov rcx, rdx
		jmp .i_get
	align 10h
	.ins_right:
		mov [rcx + this.RIGHT], rax
		jmp .balance
	.ins_left:
		mov [rcx + this.LEFT], rax


	.balance:
		mov [rax + this.PARENT], rcx ; As a red node.

		remap b->PARENT, c->NODE, di->ROOT, 15->GPARENT, d->UNCLE

		push rPARENT, rGPARENT
		mov rPARENT, rcx
		jmp .into2
		;[TODO]
	.loop:
		cmp rPARENT, [rGPARENT + this.RIGHT]
		je .right
	.left:
		mov rUNCLE, [rGPARENT + this.RIGHT]
		test rUNCLE, rUNCLE
		jz @f
		test qword [rUNCLE + this.COLOUR], 1
		jnz @f

		or  qword [rUNCLE   + this.COLOUR],     1
		or  qword [rPARENT  + this.COLOUR],     1
		and qword [rGPARENT + this.COLOUR], not 1
		mov rNODE, rGPARENT
		jmp .into
	@@:
		cmp [rPARENT + this.RIGHT], rNODE
		jne @f
		mov rsi, rPARENT
		call rbtree.rotate_left
		xchg rPARENT, rNODE
	@@:
		or  qword [rPARENT + this.COLOUR],      1
		and qword [rGPARENT + this.COLOUR], not 1
		mov rsi, rGPARENT
		call rbtree.rotate_right
		jmp .into

	.right:
		mov rUNCLE, [rGPARENT + this.LEFT]
		test rUNCLE, rUNCLE
		jz @f
		test qword [rUNCLE + this.COLOUR], 1
		jnz @f

		or  qword [rUNCLE   + this.COLOUR],     1
		or  qword [rPARENT  + this.COLOUR],     1
		and qword [rGPARENT + this.COLOUR], not 1
		mov rNODE, rGPARENT
		jmp .into
	@@:
		cmp [rPARENT + this.LEFT], rNODE
		jne @f
		mov rsi, rPARENT
		call rbtree.rotate_right
		xchg rPARENT, rNODE
	@@:
		or  qword [rPARENT + this.COLOUR],      1
		and qword [rGPARENT + this.COLOUR], not 1
		mov rsi, rGPARENT
		call rbtree.rotate_left

	.into:	mov rPARENT, [rNODE + this.PARENT]
		and rPARENT, not 1
	.into2:	test rPARENT, rPARENT
		jz .ende
		mov rGPARENT, [rPARENT + this.PARENT]
		test rGPARENT, 1
		jz .loop

	.ende:
		mov r15, [rdi + this.TREE]
		or  qword [r15 + this.PARENT], 1
		pop rbx, r15
		ret

	.root:  ;[/TODO]
		mov [rdi + this.TREE], rax
		mov qword [rax + this.PARENT], 1
		ret
	endproc

	;! Rotate the node left.
	;: RBTree A -> RBNode A -> IO ()
	;- ax, si, r10, r11
	proc rotate_left, di->ROOT, si->NODE, 10->RIGHT, 11->PARENT
		assert rROOT, ne, 0, "rbtree.rotate_left: null given as root."
		assert rNODE, ne, 0, "rbtree.rotate_left: null given as node."

		mov rRIGHT,  [rNODE + this.RIGHT]
		mov rPARENT, [rNODE + this.PARENT]
		and rPARENT, not 1

		mov rax, [rRIGHT + this.LEFT]
		mov [rNODE + this.RIGHT], rax
		test rax, rax
		jz @f

		mov r8, [rax + this.PARENT]
		and r8, 1
		or  r8, rNODE
		mov [rax + this.PARENT], r8
	@@:
		mov [rRIGHT + this.LEFT], rNODE

		mov r8, [rRIGHT + this.PARENT]
		and r8, 1
		or  r8, rPARENT
		mov [rRIGHT + this.PARENT], r8

		mov r8, [rNODE + this.PARENT]
		and r8, 1
		or  r8, rRIGHT
		mov [rNODE + this.PARENT], r8

		test rPARENT, rPARENT
		jz .setroot
		cmp rNODE, [rPARENT + this.LEFT]
		jne .setright
	.setleft:
		mov [rPARENT + this.LEFT], rRIGHT
		ret
	.setright:
		mov [rPARENT + this.RIGHT], rRIGHT
		ret
	.setroot:
		mov [rROOT + this.TREE], rRIGHT
		ret
	endproc

	;! Rotate the node right.
	;: RBTree A -> RBNode A -> IO ()
	proc rotate_right, di->ROOT, si->NODE, 10->LEFT, 11->PARENT
		assert rROOT, ne, 0, "rbtree.rotate_right: null given as root."
		assert rNODE, ne, 0, "rbtree.rotate_right: null given as node."

		mov rLEFT,  [rNODE + this.LEFT]
		mov rPARENT, [rNODE + this.PARENT]
		and rPARENT, not 1

		mov rax, [rLEFT + this.RIGHT]
		mov [rNODE + this.LEFT], rax
		test rax, rax
		jz @f

		mov r8, [rax + this.PARENT]
		and r8, 1
		or  r8, rNODE
		mov [rax + this.PARENT], r8
	@@:
		mov [rLEFT + this.RIGHT], rNODE

		mov r8, [rLEFT + this.PARENT]
		and r8, 1
		or  r8, rPARENT
		mov [rLEFT + this.PARENT], r8

		mov r8, [rNODE + this.PARENT]
		and r8, 1
		or  r8, rLEFT
		mov [rNODE + this.PARENT], r8

		test rPARENT, rPARENT
		jz .setroot
		cmp rNODE, [rPARENT + this.RIGHT]
		je .setright
	.setleft:
		mov [rPARENT + this.LEFT], rLEFT
		ret
	.setright:
		mov [rPARENT + this.RIGHT], rLEFT
		ret
	.setroot:
		mov [rROOT + this.TREE], rLEFT
		ret
	endproc
	;! Search after an entry in the tree.
	;: RBTree A -> (Int key | ? key) -> A:RBNode A
	;- rdx, rdi
	; TODO: Semaphore on the whole tree?
	proc search
		mov rdx, [rdi + this.CALLBACK]

		cmp rdx, 0
		je .search_int

	.search_callback:
		push rbx, r15
		mov r15, rdx
		mov rbx, [rdi + this.TREE]
	align 10h
	.c_loop:
		mov rdi, [rbx + this.KEY]
		call r15 ; Please don't destroy rsi. Thank you.
		cmp rax, 0
		jb .c_right
		ja .c_left
		mov rax, [rbx + this.WHAT]
		mov rdx, rbx
		pop rbx, r15
		ret
	align 10h
	.c_right:
		mov rbx, [rbx + this.RIGHT]
		test rbx, rbx
		jz .c_null
		jmp .c_loop
	align 10h
	.c_left:
		mov rbx, [rbx + this.LEFT]
		test rbx, rbx
		jz .c_null
		jmp .c_loop
	align 10h
	.c_null:
		pop rbx, r15
		xor rax, rax
		ret

	.search_int:
		mov rdi, [rdi + this.TREE]
		jmp .i_loop ; One jump < 16/3 cycles?
	align 10h
	.i_loop:
		test rdi, rdi
		jz .i_null
		cmp rsi, [rdi + this.KEY]
		ja .i_right
		jb .i_left
		mov rax, [rdi + this.WHAT]
		mov rdx, rdi
		ret
	align 10h
	.i_right:
		mov rdi, [rdi + this.RIGHT]
		jmp .i_loop
	align 10h
	.i_left:
		mov rdi, [rdi + this.LEFT]
		jmp .i_loop

	align 10h
	.i_null:
		xor rax, rax
		xor rdx, rdx
		ret
	endproc

endclass

; vim: ts=8 sw=8 syn=fasm
