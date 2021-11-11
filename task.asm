; Copyright (C) 2021 Mateus de Lima Oliveira
[bits 32]
global SwitchToUserMode

SwitchToUserMode:
	cli
	mov ax, 0x23
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	
	mov eax, esp
	push 0x23
	push eax
	pushf

	; re-enable interrupts after returning from user mode
	pop eax ; Get EFLAGS back into EAX. The only way to read EFLAGS is to pushf then pop.
	or eax, 0x200 ; Set the IF flag.
	push eax ; Push the new EFLAGS value back onto the stack.

	push 0x1B
	push return_point
	iret
return_point:

global LoadTSS    ; Allows our C code to call tss_flush().
LoadTSS:
	mov ax, 0x2B      ; Load the index of our TSS structure - The index is
					 ; 0x28, as it is the 5th selector and each is 8 bytes
					 ; long, but we set the bottom two bits (making 0x2B)
					 ; so that it has an RPL of 3, not zero.
	ltr ax            ; Load 0x2B into the task state register.
	ret 
