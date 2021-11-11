; Copyright (C) 2021 Mateus de Lima Oliveira
[bits 32]
global EnablePaging

EnablePaging:
	mov eax, [esp + 4] ; Page addresses
	mov cr3, eax
	mov eax, cr0
	or eax, 0x80000000 ; Enable paging
	mov cr0, eax
	ret
