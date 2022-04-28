; Copyright (C) 2021 Mateus de Lima Oliveira
[bits 32]
global SwitchToUserMode

SwitchToUserMode:
	mov ax, 0x23
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	add esp, 4 
	pop ebx
	pop ecx
	pop edx
	pop esi
	pop edi
	pop ebp
	pop eax
	
	push 0x23
	push DWORD[esp + 0 + 4*1] ; esp
	pushf
	push 0x1B
	push DWORD[esp + 4 + 4*4] ; eip
	iret

global LoadTSS    ; Allows our C code to call tss_flush().
LoadTSS:
	mov ax, 0x2B      ; Load the index of our TSS structure - The index is
					 ; 0x28, as it is the 5th selector and each is 8 bytes
					 ; long, but we set the bottom two bits (making 0x2B)
					 ; so that it has an RPL of 3, not zero.
	ltr ax            ; Load 0x2B into the task state register.
	ret

global sys_print
sys_print:
	push ebx
	push ecx
	mov ebx, [esp + 12]
	mov ecx, [esp + 16]
	mov eax, 69
	int 0x80
	pop ecx
	pop ebx
	ret

global sys_mmap
sys_mmap:
	push ebx
	push ecx
	mov ebx, [esp + 12]
	mov ecx, [esp + 16]
	mov eax, 1
	int 0x80
	pop ecx
	pop ebx
	ret
