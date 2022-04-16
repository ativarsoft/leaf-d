; Copyright (C) 2021 Mateus de Lima Oliveira
global start
extern main
extern end

MODULEALIGN        equ        1<<0
MEMINFO            equ        1<<1
FLAGS              equ        MODULEALIGN | MEMINFO
MAGIC              equ        0x1BADB002
CHECKSUM           equ        -(MAGIC + FLAGS)

section .text      ; Next is the Grub Multiboot Header

align 4
MultiBootHeader:
	dd MAGIC
	dd FLAGS
	dd CHECKSUM

STACKSIZE equ 0x4000

start:
    cli   
	mov esp, STACKSIZE+stack

	; !!!
	push end
	push stack
	push ebx ; Multiboot information structure
	push eax ; magic

	call main
	
	jmp cpuhalt ; !!!

cpuhalt:
	hlt
	jmp cpuhalt

section .bss
;align 32
align 0x10000

stack:
      resb      STACKSIZE
