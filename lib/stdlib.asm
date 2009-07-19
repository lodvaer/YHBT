

EXIT_FAILURE = 1
EXIT_SUCCESS = 0

NULL         = 0

RAND_MAX     = 1 shl 32 - 1

; include 'lib/wait.asm' ?

WNOHANG      = 0
WUNTRACED    = 0
WEXITSTATUS  = 0
WIFEXITED    = 0
WIFSIGNALED  = 0
WIFSTOPPED   = 0
WSTOPSIG     = 0
WTERMSIG     = 0

; Constants:
_Exit = panic
abort = panic
exit = panic


append TO_INIT_64, malloc.init
macro malloc.init {
	mov rax, MALLOC_MAX
	mov rbx, [malloc.base]
	mov [rbx], rax
}

ivar malloc.base, HIGH_HALF + MALLOC_ORIG
ivar malloc.max,  MALLOC_MAX
var malloc.current

;! Allocate memory before the init routines are done.
;: Int size -> *Mem
; Please note that there is no preinit_free...
preinit_malloc:
	mov rax, [malloc.base]
	add [malloc.base], rdi
	sub [malloc.max], rdi
	ret

;! Allocate memory
;: Int size -> *Mem
;- rdi, rsi
; rdi should (if not must) be a multiple of 8
; to not screw up the alignment.
malloc:
	assert rdi, ne, 0, "malloc: Called with 0."
	assert_t rdi, z, 7, "malloc: 8-byte aligned, please."
	push rbx, r15
	xor r15, r15
	mov rbx, [.base]
	mov rsi, [.current]
.loopy:
	cmp rsi, [.max]
	jae .fail

	mov rax, [rbx + rsi]
	assert rax, ne, 0, "malloc: size of 0."
	btr rax, 63	; Test a bit to see if it's clear or not.
	jnc .found
	add rsi, rax
	add rsi, 8

	jmp .loopy
align 10h
.found:
	; TODO: Collapse multiple.

	cmp rax, rdi	; Large neough?
	je  .win_eq
	ja  .win_a
	add rsi, rax	; Not? Next!
	add rsi, 8
	jmp .loopy
align 10h
.win_eq:		; Exact size!
	;mov [.current], rsi
	bts rax, 63	; Taken
	mov [rbx + rsi], rax	; It's the exact size, so don't bother
	lea rax, [rbx + rsi+8]	; with splitting.
	pop rbx, r15
	ret
align 10h
.win_a:			; Larger than needed.
	bts rdi, 63
	mov [rbx + rsi], rdi
	btr rdi, 63
	sub rax, rdi
	add rsi, rdi
	add rsi, 8
	
	mov [rbx + rsi], rax
	;mov [.current], rsi
	sub rsi, rdi
	sub rsi, 8
	lea rax, [rbx + rsi+8]
	pop rbx, r15
	ret

.fail:
	or r15, r15
	jnz .realfail ; Because the pointer is forever moving, we try twice.
	inc r15
	mov rsi, 0
	jmp .loopy
.realfail:
	; No, we seriously failed..
	; TODO:
	;	Allocate another page
	;	Try again until there are no more pages.
	mov rax, -1
	pop rbx, r15
	ret

;! Free a previously allocated pointer.
;: *Mem -> Null
; The exception library depends on this not fucking up rax
free:
	btr qword [rdi - 8], 63
	ret
; Unimplemented:
a64l:
l64a:

abs:
atexit:
atof:
atoi:
atol:
atoll:
bsearch:
calloc:
_div:
drand48:
ecvt:
erand48:
fcvt:

gcvt:
getenv:
getsubopt:
grantpt:
initstate:
jrand48:
labs:
lcong48:
ldiv:
llabs:
lldiv:
lrand48:
mblen:
mbstowcs:
mbtowc:
mktemp:
mkstemp:
mrand48:
nrand48:
posix_memalign:
posix_openpt:
ptsname:
putenv:
qsort:
rand:
rand_r:
random:
realloc:
realpath:
setenv:
setstate:
srand:
srand48:
srandom:
strtod:
strtof:
strtol:
strtold:
strtoll:
strtoul:
strtoull:

system:
unlockpt:
unsetenv:
wcstombs:
wctomb:
; vim: ts=8 sw=8 syn=fasm
