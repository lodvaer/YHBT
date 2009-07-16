; Kernel-specific mm-stuff.
; Among other things:
;  Paging; paddr_alloc, paddr_free, palloc, pfree,
;          copying page directories,
;          cloning page directories.
;  SLAB? Fuck it, we just allocate so-and-so many pages.
;     (Turns out, this is actually SLAB... At least from what Jari OS told me)

append TO_INIT_16, mm.init_16
macro mm.init_16 {
	; TODO: Detect memory here.
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
	mov [PAGE_ORIG], rax ; Unhook the lower.

	mov rax, cr4
	bts rax, CR4.PGE ; Enable global pages.
	mov cr4, rax


	mov rdi, 64 + 8    ; 64*8=512 pages, Int for the offset, and *Mem for the next.
	call preinit_malloc
	mov [mm.phead], rax
	mov rdi, rax
	mov rsi, -1
	mov edx, 64
	call memset
	mov qword [rdi + 64], 0

}
class mm
	ivar phead, 0

	;! Allocate and map a page into a page table
	;: *Mem loc -> (PML4|0) -> -> *Mem page
	;. this.paddr_get
	;- rax, r10, r11, r8
	proc palloc
		assert rdi, ne, 0, "mm.palloc: page at 0 requested..."

		push rbx
		mov rbx, IDENT_MAP
		xchg rdi, rsi

		cmp rdi, 0
		jne .got_it
		mov rdi, cr3
	.got_it:
		add rdi, rbx
		call mm.pdp_get
		mov rdi, rax

		add rdi, rbx
		call mm.pd_get
		mov rdi, rax

		add rdi, rbx
		call mm.pt_get
		mov rdi, rax

		add rdi, rbx
		call mm.pageloc_get

		add rax, rbx
		pop rbx
		ret
	endproc

	;! Get the pdp address of the provided pml4 and address
	;: *PML4 -> *Mem fin_loc -> *PDP
	;- rdx, r10
	;. mm.paddr_hook
	proc pdp_get
		mov rdx, rsi
		mov r10, 1FFh shl 39
		and rdx, r10
		shr rdx, 39 - 3
		mov rax, [rdi + rdx]
		bt  rax, 0
		jc  .over
		call mm.paddr_hook
	.over:	and rax, not 7FFh ; Clear the priviledge bits.
		ret
	endproc

	;! Get the PD address of the provided PDP and address
	;: *PDP -> *Mem fin_loc -> *PD
	;- rdx, r10
	;. mm.paddr_hook
	proc pd_get
		mov rdx, rsi
		mov r10, 1FFh shl 30
		and rdx, r10
		shr rdx, 30 - 3
		mov rax, [rdi + rdx]
		bt  rax, 0
		jc  .over
		call mm.paddr_hook
	.over:	and rax, not 7FFh
		ret
	endproc

	;! Get the PT address of the provided PD and address
	;: *PD -> *Mem fin_loc -> *PT
	;- rdx, r10
	;. mm.paddr_hook
	proc pt_get
		mov rdx, rsi
		mov r10, 1FFh shl 21
		and rdx, r10
		shr rdx, 21 - 3
		mov rax, [rdi + rdx]
		bt  rax, 0
		jc  .over
		call mm.paddr_hook
	.over:	and rax, not 7FFh
		ret
	endproc

	;! Get the final physical page location of the provided PT and address
	;: *PT -> *Mem fin_loc -> *Page
	;- rdx, r10
	;. mm.paddr_hook
	proc pageloc_get
		mov rdx, rsi
		mov r10, 1ffh shl 12
		and rdx, r10
		shr rdx, 12 - 3
		mov rax, [rdi + rdx]
		jc  .over
		call mm.paddr_hook
	.over:	and rax, not 7FFh
		ret
	endproc

	;! Allocate a page and hook it into the provided table, returning the allocated
	;: *PTable tbl -> *Mem fin_loc -> Int (offset * 8) -> *PhysPage allocated_page
	;. mm.paddr_get
	;+ rdi, rsi, rdx
	; TODO: Clear memory before running it on IRL HW.
	proc paddr_hook
		push rdi, rsi, rdx
		call mm.paddr_get
		pop rdi, rsi, rdx
		or  rax, 3
		bt  rsi, 63
		jc @f
		bts rax, 2		; PDE.U
	@@:	mov [rdi + rdx], rax
		ret
	endproc

	;! Get the physical location of a free page
	;: *Mem
	;- rdi, rsi, rcx, rdx
	; O(num_pages)
	; TODO: Fail if OOM. Better algorithm.
	proc paddr_get
		mov rdi, [this.phead]	; *Mem with space for 512 pages
		xor rsi, rsi		; Accumulator
		xor rcx, rcx		; Counter.
		jmp .in
	.loopy:
		inc rcx		; Search for the first clear bit.
		cmp rcx, 8
		je .next
	.in:	bsf rax, [rdi + rcx*8]
		jz .loopy
	.win:
		btr [rdi + rcx*8], rax

		; Calculate physical adress:
		shl rax, 12
		shl rcx, 18
		shl rsi, 21
		add rax, rcx
		add rax, rsi ; rax = rax*1000h + rcx*40000h + rsi*200000h
		add rax, 400000h ; And the first 4MiB are taken anyway.
		ret

	.next:
		inc rsi		; The next in the list
		xor rcx, rcx
		mov rdx, rdi
		mov rdi, [rdx + 64]
		or rdi, rdi
		jnz .in
	.alloc:
		push rsi
		push rdx	; We're at the end of the list, get a new one.
		mov rdi, 64 + 8
		call malloc
		mov rdi, rax
		mov rsi, -1
		mov rdx, 64
		;*+ rdi
		call memset
		pop rdx
		mov qword [rdi + 64], 0
		mov [rdx + 64], rdi
		xor rcx, rcx
		pop rsi
		jmp .in
	endproc

	;! Free the physical location of a free page
	;: *Mem -> ()
	;- rdi, rsi, rdx
	proc paddr_free
		mov rsi, rdi ; rcx: How many steps out
		shr rsi, 21
		mov rdx, [this.phead]
		test rsi, rsi
		jz .over
	.loop:
		mov rdx, [rdx + 64]
		dec rsi
		jnz .loop
	.over:
		mov rsi, rdi
		and rdi,  3F000h
		and rsi, 1C0000h
		shr rdi, 12
		shr rsi, 18

		bts [rdx + rsi*8], rdi
		ret
	endproc
endclass
; vim: ts=8 sw=8 syn=fasm
