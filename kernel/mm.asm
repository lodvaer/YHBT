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

class mm
endclass
; vim: ts=8 sw=8 syn=fasm
