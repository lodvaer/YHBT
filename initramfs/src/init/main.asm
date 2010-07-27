;; /sbin/init

use64
org 200000h
start:
	times 50 nop
	jmp start
; vim: ts=8 sw=8 syn=fasm
