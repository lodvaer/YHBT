;; For loading directly from an MBR.

org 07C00h		; We are safe here until the kernel reaches 27 KiB
	jmp 0:start
msg:
.start:	db 10, 10, 10, "=> Blind and stupid bootloader.", 13, 10,10, 0
.fail:	db "1: NOES!", 0
.no32:	db "Lacking 32-bit.", 0
.nolong:db "Lacking longmode.", 0
b:
.drv:	db	0

start:
	mov byte [b.drv], dl
	mov si, msg.start
	call puts
	
	; Check for 80386
	pushf		; Initial push
	push 0
	popf		; Clear flags
	pushf
	pop ax		; Get flags
	and ah, 0F0h
	cmp ah, 0F0h
	je no32		; Byte 15 can be set on 386
	mov ah, 70h
	push ax
	popf
	pushf
	pop ax
	and ah, 70h	; And if we can't set that flag,
	jz no32		; no 386
	popf		; And pop the initial push.

	; Check for amd64
	mov eax, 80000000h
	cpuid
	cmp eax, 80000000h
	jb no32
	mov eax, 80000001h
	cpuid
	bt edx, 29
	jnc nolong
	
;	call enableA20
	in al, 092h
	or al, 2
	out 092h, al

	mov dl, [b.drv]			;  1 shl 7 or 1b
	xor ah, ah
	int 13h
	jc fail

	mov byte [msg.fail], '2'	; Update error code.
	
	mov ax, 0
	mov es, ax
	mov bx, 1000h

	mov ah, 02h	; Read
	mov al, 30h	; 24 KiB
			; From
	mov ch, 0	; Cylynder 0
	mov cl, 2	; Sector 2
	mov dh, 0	; Head 0
	mov dl, [b.drv]	; (hd0)

	int 13h		; GO
	jc fail
	mov byte [msg.fail], '3'
	jmp 0:1000h

fail:	
	mov si, msg.fail
	call puts
	jmp lop
no32:
	mov si, msg.no32
	call puts
	jmp lop
nolong:
	mov si, msg.nolong
	call puts
	jmp lop

enableA20:
	cli
	
	call .wait
	mov al, 0ADh
	out 064h, al

	call .wait
	mov al, 0D0h
	out 064h, al

	call .wait2
	in al, 060h
	push ax

	call .wait
	mov al, 0D1h
	out 064h, al

	call .wait
	pop ax
	or al, 2
	out 060h, al

	call .wait
	mov al, 0AEh
	out 064h, al

	call .wait
	sti
	ret

.wait:
	in al, 064h
	test al, 2
	jnz .wait
	ret
.wait2:
	in al, 064h
	test al, 1
	jz .wait2
	ret

puts.lop:
	mov bx, 1
	mov ah, 0eh
	int 10h
puts:
	lodsb
	or al, al
	jnz .lop
	ret


lop:	hlt
	jmp lop

times (1FEh - ($-07C00h)) db 0
	db 55h
	db 0AAh

include '../OS.asm'
; vim: ts=8 sw=8 syn=fasm
