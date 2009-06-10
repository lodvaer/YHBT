; Calltracing in initialization code is not good
CALLTRACE_ACTIVE = 0

;; Initialize CPU
use16
	cli
	mov ax, cs
	mov ds, ax
	mov ss, ax
	mov ax, -1
	mov sp, ax
	

match I, TO_INIT_16 {
	irp do_init, I  \{
		do_init
	\}
}
	lgdt [cs:GDT]
	mov eax, (1 shl CR0.PE) or (1 shl CR0.ET)
	mov cr0, eax

	jmp far SEL_CODE:.pm_start

use32

.pm_start:
	mov ax, SEL_DATA
	mov ds, ax
	mov es, ax
	mov ss, ax

	mov eax, cr4
	bts eax, CR4.PAE
	mov cr4, eax

	; For paging, see kernel/mm.asm
match I, TO_INIT_32 {
	irp do_init, I  \{
		do_init
	\}
}
	mov ecx, EFER
	rdmsr
	bts eax, EFER.LME
	bts eax, EFER.SCE
	wrmsr

	mov eax, cr0
	bts eax, CR0.PG
	mov cr0, eax

	jmp SEL_LONG:.lm_start

use64

.lm_start:
	mov rax, (9FFF8h + HIGH_HALF)
	mov rsp, rax

	mov qword [TSS.rsp0], rax
	mov qword [TSS.rsp1], rax
	mov qword [TSS.rsp2], rax
	mov qword [TSS.ist1], rax

	xor rax, rax
	mov ax, SEL_TSS
	ltr ax

	mov rax, (.high_half + HIGH_HALF)
	jmp rax
.high_half:

	mov rax, GDT.rGDT + HIGH_HALF
	mov [GDT.loc], rax
	lgdt [GDT]

match I, TO_INIT_64 {
	irp do_init, I  \{
		do_init
	\}
}
	; TODO: Load the initramfs, load /sbin/init,
	; and jump to the main proc loop.
	jmp kmain
; vim: ts=8 sw=8 syn=fasm
