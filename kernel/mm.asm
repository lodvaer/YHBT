; Kernel-speciffic mm-stuff.
; Among other things:
;  Paging; paddr_alloc, paddr_free, palloc, pfree,
;          copying page directories,
;          cloning page directories.
;  SLAB? Fuck it, we just allocate so-and-so many pages.
;     (Turns out, this is actually SLAB... At least from what Jari OS told me)

append TO_INIT_16, mm.init_16
macro mm.init_16 {
	; Detect memory here.
}
append TO_INIT_32, mm.init_32
macro mm.init_32 {
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
}
append TO_INIT_64, mm.init_64
macro mm.init_64 {
	xor rax, rax
	mov [PAGE_ORIG], rax ; Unhook the lower 

	mov rax, cr4
	bts rax, CR4.PGE ; Enable global pages.
	mov cr4, rax
}
class mm
endclass
; vim: ts=8 sw=8 syn=fasm
