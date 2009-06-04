multiboot:
	dd 01badb002h
	dd 1 shl 16
	dd 0 - 01badb002h - 1 shl 16
	dd multiboot + 100000h
	dd _START + 100000h
	dd _END + 100000h
	dd 0
	dd booty.faggityfagfag
org $ + 100000h
use32
booty.faggityfagfag: ; "unable to load kernel under 1MB" GAWD!!
	cli
	mov ecx, _END - _START
	mov esi, _START + 100000h
	mov edi, _START
.loopy:
	mov al, [esi]
	mov [edi], al
	inc esi
	inc edi
	loop .loopy
	jmp _START
org $ - 100000h
include '../OS.asm'
; vim: ts=8 sw=8 syn=fasm
