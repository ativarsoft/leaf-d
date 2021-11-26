; Copyright (C) 2021 Mateus de Lima Oliveira
[bits 32]
extern isrHandler
global load_idt
global EnableInterrupts
global DisableInterrupts

load_idt:
	mov eax, [esp + 4]
	lidt [eax]
	; Test interrupts
	int 3
	int 4
	ret

EnableInterrupts:
	sti
	ret

DisableInterrupts:
	cli
	ret

%macro isr_noerror 1
global isr%1
isr%1:
	cli
	push 0
	push %1
	jmp isr_stub
%endmacro

%macro isr_error 1
global isr%1
isr%1:
	cli
	push %1
	jmp isr_stub
%endmacro

isr_noerror 0
isr_noerror 1
isr_noerror 2
isr_noerror 3
isr_noerror 4
isr_noerror 5
isr_noerror 6
isr_noerror 7
isr_error 8
isr_noerror 9
isr_error 10
isr_error 11
isr_error 12
isr_error 13
isr_error 14
isr_noerror 15
isr_noerror 16
isr_noerror 17
isr_noerror 18
isr_noerror 19
isr_noerror 20
isr_noerror 21
isr_noerror 22
isr_noerror 23
isr_noerror 24
isr_noerror 25
isr_noerror 26
isr_noerror 27
isr_noerror 28
isr_noerror 29
isr_noerror 30
isr_noerror 31

; IRQs
isr_noerror 32
isr_noerror 33
isr_noerror 34
isr_noerror 35
isr_noerror 36
isr_noerror 37
isr_noerror 38
isr_noerror 39
isr_noerror 40
isr_noerror 41
isr_noerror 42
isr_noerror 43
isr_noerror 44
isr_noerror 45
isr_noerror 46
isr_noerror 47

; syscall
isr_noerror 128 ; 0x80

isr_stub:
	pusha ; Push All General-Purpose Registers
	
	; Push the segment for the IDT handler function
	; and save it on the esi register to be restored
	; after the function call.
	mov ax, ds
	push eax
	;mov esi, eax
	
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	
	call isrHandler
	
	pop eax
	
	; Restore segment registers
	;mov eax, esi
	
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	
	popa ; Restore general-purpose registers from the stack
	add esp, 8 ; Remove the values pushed by the isr# routine
	sti
	iret
