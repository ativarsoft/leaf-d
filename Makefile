# Copyright (C) 2021 Mateus de Lima Oliveira
DLANG=ldc2
FLAGS=--march=x86 --mcpu=i386

#DLANG=dmd
#FLAGS=-m32 -gs -preview=all

LD=ld.lld

all: kernel.bin

ASM_SOURCES= \
	start.asm \
	v86.asm \
	gdt.asm \
	idt.asm \
	common.asm \
	paging.asm \
	task.asm
D_SOURCES= \
	kernel.main.d \
	kernel.console.d \
	kernel.gdt.d \
	kernel.idt.d \
	kernel.isr.d \
	kernel.common.d \
	kernel.pit.d \
	kernel.multiboot.d \
	kernel.paging.d \
	kernel.heap.d \
	kernel.orderedlist.d \
	kernel.task.d \
	kernel.memorystream.d \
	kernel.tss.d \
	kernel.syscall.d \
	kernel.init.d \
	leaf.compiler.d \
	leaf.syscall.d \
	kernel.serial.d

kernel.bin: $(ASM_SOURCES) $(D_SOURCES) linker.ld
	nasm -f elf -o start.o start.asm
	nasm -f elf -o v86.o v86.asm
	nasm -f elf -o gdt.o gdt.asm
	nasm -f elf -o idt.o idt.asm
	nasm -f elf -o common.o common.asm
	nasm -f elf -o paging.o paging.asm
	nasm -f elf -o task.o task.asm
	#gdc -fno-exceptions -fno-moduleinfo -nophoboslib -m32 -c kernel.main.d -o kernel.main.o -g
	# removed stack stomp
	$(DLANG) $(FLAGS) -betterC -c $(D_SOURCES) -g
	$(LD) -melf_i386 -T linker.ld -o kernel.bin \
		$(patsubst %.asm,%.o,$(ASM_SOURCES)) \
		$(patsubst %.d,%.o,$(D_SOURCES))

cdrom.iso: kernel.bin
	cp $^ isofiles/boot
	genisoimage -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o cdrom.iso isofiles

runcd: cdrom.iso
	qemu-system-i386 -cdrom cdrom.iso

run: kernel.bin
	qemu-system-i386 -kernel kernel.bin -serial stdio

debug: kernel.bin
	qemu-system-i386 -s -S -kernel kernel.bin

clean:
	rm -f cdrom.iso
	rm -fr kernel.bin *.o
	rm -f isofiles/boot/kernel.bin

.PHONY: run debug clean
