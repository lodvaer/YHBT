;; Font file.

; Each set of characters takes 2.75 KiB.

.00:
db 00000000b
db 00000000b ; <- Preferably air

db 00000000b
db 00000000b ; <- High part

db 01111000b
db 10000100b ; <- Character
db 10000100b
db 10000100b
db 10001100b
db 01110110b

db 00000000b
db 00000000b ; <- Lower part

; vim: ts=8 sw=8 syn=fasm
