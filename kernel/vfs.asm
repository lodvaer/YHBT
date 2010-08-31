;; Virtual File System
;; TODO. This is but a dummy.

class vfs
	;! Read from a file descriptor into memory.
	;: Int fd -> *Mem buf -> Int size -> Int read_size
	;= read
	; TODO: Should not be in the vfs.
	proc 0, read
	read = vfs.read
		assert rdi, na, 0, "The current VFS is dumb and only works on fd 0"
		cmp rdx, file_init.size
		jb .over
		mov rdx, file_init.size
	.over:
		mov rdi, rsi
		lea rsi, [file_init]
		tailcall memcpy
	endproc
	;! Open a file
	;: *Char filename -> Int flags -> Int fd
	;= open
	proc 0, open
	open = vfs.open
		mov eax, 0
		ret
	endproc
endclass


file_init:
file 'initramfs/sbin/init'
file_init.size = $ - file_init
