

	mov edi, PAGE_ORIG
	mov ecx, 6000h
	xor eax, eax
	rep stosd

	; 2MB pages
	.PDE = PDE.P + PDE.W + PDE.G
	; PML4
	mov dword [PAGE_ORIG        ], PAGE_ORIG + 1000h + .PDE ; TMP
	mov dword [PAGE_ORIG + 0800h], PAGE_ORIG + 1000h + .PDE ; -> Kernel PDPE
	mov dword [PAGE_ORIG + 0F00h], PAGE_ORIG + 3000h + .PDE ; -> Ident  PDPE
	; Kernel PDPE
	mov dword [PAGE_ORIG + 1000h], PAGE_ORIG + 2000h + .PDE ; -> Kernel PDE
	; Kernel PDE, 4 MiB total
	mov dword [PAGE_ORIG + 2000h], 000000h + .PDE + PDE.PS ; 1
	mov dword [PAGE_ORIG + 2008h], 200000h + .PDE + PDE.PS ; 2
	; Ident PDPE
	mov dword [PAGE_ORIG + 3000h], PAGE_ORIG + 4000h + .PDE ; -> Ident PDE

	; Ident PDE, 1 GiB total
	xor ecx, ecx
	mov edi, .PDE + PDE.PS
@@:	mov dword [PAGE_ORIG + 4000h + ecx*4], edi
	add edi, 200000h
	add ecx, 2
	cmp ecx, 1024
	jne @b
	.PDE = PDE.P + PDE.W + PDE.U
	; Lusermode PDPE
	mov dword [PAGE_ORIG + 5000h], PAGE_ORIG + 6000h + .PDE
	; Lusermode PDE, 2 MiB
	mov dword [PAGE_ORIG + 6008h], 600000h + .PDE + PDE.PS

	mov eax, PAGE_ORIG
	mov cr3, eax

; vim: ts=8 sw=8 syn=fasm
