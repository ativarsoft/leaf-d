global start
extern main        ; Allow main() to be called from the assembly code
extern start_ctors, end_ctors, start_dtors, end_dtors
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

STACKSIZE equ 0x4000  ; 16 KiB if you're wondering

static_ctors_loop:
	mov ebx, start_ctors
	jmp .test
.body:
	call [ebx]
	add ebx,4
.test:
	cmp ebx, end_ctors
	jb .body

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

static_dtors_loop:
	mov ebx, start_dtors
	jmp .test
.body:
	call [ebx]
	add ebx,4
.test:
	cmp ebx, end_dtors
	jb .body


cpuhalt:
	hlt
	jmp cpuhalt

section .bss
;align 32
align 0x10000

stack:
      resb      STACKSIZE
