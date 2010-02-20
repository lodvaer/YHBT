
;! Check that it rotates correctly
proc 0, rbtree_rotate
	lea rdi, [.tree]
	mov rsi, [rdi + rbtree.TREE]
	push rsi
	call rbtree.rotate_left

	
	lea rdi, [.tree]
	mov rsi, [rdi + rbtree.TREE]
	call rbtree.rotate_right

	
	lea rdi, [.tree]
	mov rdi, [rdi + rbtree.TREE]
	pop rsi

	assert rdi, e, rsi, "Tests: rbtree_rotate 0: FAILED"

	_puts "RBTree Rotate: Win!"
	ret

.tree:
dq 0, HIGH_HALF + .node

.node:
dq 0, HIGH_HALF + .left, HIGH_HALF + .right, 5, 55h

	.left:
	dq .node + HIGH_HALF, .left_left + HIGH_HALF, .left_right + HIGH_HALF, 3, 33h
		.left_left:
		dq .left + HIGH_HALF, 0, 0, 2, 22h
		.left_right:
		dq .left + HIGH_HALF, 0, 0, 4, 44h
	.right:
	dq .node + HIGH_HALF, .right_left + HIGH_HALF, .right_right + HIGH_HALF, 7, 77h
		.right_left:
		dq .right + HIGH_HALF, 0, 0, 6, 66h
		.right_right:
		dq .right + HIGH_HALF, 0, 0, 8, 88h
endproc

;! Check that it balances correctly.
proc 0, rbtree_balance
	xor rdi, rdi
	call rbtree.new
	mov rbx, rax

	mov r15, 20h
.loop:
	mov rdi, rbx
	mov rsi, r15
	mov rdx, r15
	shl rdx, 4
	call rbtree.insert

	dec r15
	jnz .loop

	mov rdi, rbx
	call rbtree.first
	call tests._rbtree_black_depth
	push rax

	mov rdi, rbx
	call rbtree.last
	call tests._rbtree_black_depth
	push rax

	mov rdi, rbx
	mov rsi, 10h
	call rbtree.search
	mov rdi, rdx
	call tests._rbtree_black_depth

	pop rdx
	pop rdi
	assert rdx, e, rdi, "Tests: rbtree_balance: first black-depth does not equal last."
	assert rdx, e, rax, "Tests: rbtree_balance: 10th black-depth does not equal first or last."

	_puts "RBTree Balance: Woho!"
	ret

endproc

proc 0, _rbtree_black_depth
	xor rax, rax
@@:	test qword [rdi + rbtree.PARENT], 1
	jz .over
	inc rcx
.over:	mov rdi, [rdi + rbtree.PARENT]
	and rdi, not 1
	test rdi, rdi
	jnz @b
	inc rax ; Just for it to truly live up to it's name.
	ret
endproc
append tests.torun, this.rbtree_rotate
append tests.torun, this.rbtree_balance
; vim: ts=8 sw=8 syn=fasm
