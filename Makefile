# Copyright (C) 2021 Mateus de Lima Oliveira
DLANG=ldc2
FLAGS=--march=x86 --mcpu=i386

#DLANG=dmd
#FLAGS=-m32 -gs

all: kernel.bin

kernel.bin: start.asm kernel.main.d linker.ld v86.asm gdt.asm kernel.console.d kernel.gdt.d kernel.idt.d idt.asm kernel.isr.d kernel.common.d kernel.pit.d common.asm kernel.multiboot.d kernel.paging.d kernel.heap.d paging.asm kernel.orderedlist.d kernel.task.d kernel.memorystream.d task.asm kernel.tss.d kernel.syscall.d kernel.init.d
	nasm -f elf -o start.o start.asm
	nasm -f elf -o v86.o v86.asm
	nasm -f elf -o gdt.o gdt.asm
	nasm -f elf -o idt.o idt.asm
	nasm -f elf -o common.o common.asm
	nasm -f elf -o paging.o paging.asm
	nasm -f elf -o task.o task.asm
	#gdc -fno-exceptions -fno-moduleinfo -nophoboslib -m32 -c kernel.main.d -o kernel.main.o -g
	# removed stack stomp
	$(DLANG) $(FLAGS) -betterC -c kernel.main.d kernel.console.d kernel.gdt.d kernel.idt.d kernel.isr.d kernel.common.d kernel.pit.d kernel.multiboot.d kernel.paging.d kernel.heap.d kernel.orderedlist.d kernel.task.d kernel.memorystream.d kernel.tss.d kernel.syscall.d kernel.init.d -g
	ld -melf_i386 -T linker.ld -o kernel.bin start.o kernel.main.o kernel.console.o kernel.gdt.o kernel.idt.o v86.o gdt.o idt.o kernel.isr.o kernel.common.o kernel.pit.o common.o kernel.multiboot.o kernel.paging.o kernel.heap.o paging.o kernel.orderedlist.o kernel.task.o kernel.memorystream.o task.o kernel.tss.o kernel.syscall.o kernel.init.o

cdrom.iso: kernel.bin
	cp $^ isofiles/boot
	genisoimage -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o cdrom.iso isofiles

runcd: cdrom.iso
	qemu-system-i386 -cdrom cdrom.iso

run: kernel.bin
	qemu-system-i386 -kernel kernel.bin

debug: kernel.bin
	qemu-system-i386 -s -S -kernel kernel.bin

clean:
	rm -f cdrom.iso
	rm -fr kernel.bin *.o
	rm -f isofiles/boot/kernel.bin

.PHONY: run debug clean
