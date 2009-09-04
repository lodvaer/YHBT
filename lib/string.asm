; Implement as needed.


memccpy:
memcht:
memcmp:
;! Copy memory from one location to another
;: *Mem dest -> *Mem src -> Int size -> IO ()
;- rcx
; TODO: Optimize.
memcpy:
	cld
	mov rcx, rdx
	rep movsb
	sub rsi, rdx
	sub rdi, rdx
	ret
memmove:

;; Set memory
;: *Mem s -> Char contents -> Int length-> IO ()
;- rcx
; TODO: Optimize.
memset:
	mov rcx, rdx
	mov eax, esi
	rep stosb
	sub rdi, rdx
	ret

; Attempted optimization, or something like that.
.loop:	; movntq [rdi], rsi
	inc rdi
	dec rdx
	jnz .loop
	ret
strcat:
strchr:
strcmp:
strcoll:
strcpy:
strcspn:
strdup:
strerror:
strerror_r:
;; Find the length of a null-terminated string
;: *Char str -> Int
strlen:
	assert eax, e, 0, "strlen: eax not 0!"
	cmp byte [rdi], 0
	rete
.loop:	inc eax
	inc rdi
	cmp byte [rdi], 0
	jne .loop
	sub rdi, rax
	ret
	
strncat:
strncmp:
strncpy:
strpbrk:
strrchr:
strspn:
strstr:
strtok:
strcfrm:

; vim: ts=8 sw=8 syn=fasm
