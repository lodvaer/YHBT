;; Standard library definitions.

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
var_lock malloc.lock

;! Allocate memory before the init routines are done.
;: Int size -> *Mem
; Please note that there is no preinit_free...
preinit_malloc:
	mov rax, [malloc.base]
	add [malloc.base], rdi
	sub [malloc.max], rdi
	ret

;! Allocate memory aligned by 10h
;: Int size -> *Mem
;- rdi, rsi
proc 0, malloc_a10h
	add rdi, 8
	call malloc
	test eax, 0Fh
	retz
	mov rsi, [rax - 8]
	sub rsi, 8
	mov qword [rax - 8], 0
	mov [rax], rsi
	add rax, 8
	ret
endproc

;! Allocate memory
;: Int size -> *Mem
;- rdi, rsi
; rdi must be a multiple of 8 to not screw up the alignment.
; TODO: Make one that isn't teh suck.
proc 0, malloc
	push rbx, r15
	spinlock save, .lock, a, b
	assert rdi, ne, 0, "malloc: Called with 0."
	assert_t rdi, z, 07h, "malloc: 8-byte aligned, please."
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
;	mov [.current], rsi
	bts rax, 63	; Taken
	mov [rbx + rsi], rax	; It's the exact size, so don't bother
	spinunlock save, .lock
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
;	mov [.current], rsi
	sub rsi, rdi
	sub rsi, 8
	spinunlock save, .lock
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
	;spinunlock save, .lock
	mov rax, -1
	pop rbx, r15
	ret
endproc

;! Free a previously allocated pointer.
;: *Mem -> Null
; The exception library depends on this not fucking up rax
free:
	btr qword [rdi - 8], 63
	ret
macro _free what {
	btr qword [what - 8], 63
}
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

var rand.state1
var rand.state2
; TODO: "Carefully choose" this constant to something better.
RAND_CONST equ 0836DFA444599DDE4h
;! Simple multiply-with-carry prng
;: IO Int
;- rdx
rand:
	mov rax, RAND_CONST
	mul qword [.state2]
	add rdx, [.state1]
	adc rax, 0
	mov [.state1], rax
	mov [.state2], rdx
	mov rax, rdx
	ret

rand_r:
random:
realloc:
realpath:
setenv:
setstate:

;! Seed the random number generator
;: Int -> Int -> IO ()
srand:
	mov [rand.state1], rdi
	mov [rand.state2], rsi
	ret

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
