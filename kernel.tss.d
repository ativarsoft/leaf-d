// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.tss;
import kernel.common;
import kernel.gdt;

// A struct describing a Task State Segment.
struct TSSEntry
{
	align (1):
	uint prev_tss;   // The previous TSS - if we used hardware task switching this would form a linked list.
	uint esp0;       // The stack pointer to load when we change to kernel mode.
	uint ss0;        // The stack segment to load when we change to kernel mode.
	uint esp1;       // Unused...
	uint ss1;
	uint esp2;  
	uint ss2;   
	uint cr3;   
	uint eip;   
	uint eflags;
	uint eax;
	uint ecx;
	uint edx;
	uint ebx;
	uint esp;
	uint ebp;
	uint esi;
	uint edi;
	uint es;         // The value to load into ES when we change to kernel mode.
	uint cs;         // The value to load into CS when we change to kernel mode.
	uint ss;         // The value to load into SS when we change to kernel mode.
	uint ds;         // The value to load into DS when we change to kernel mode.
	uint fs;         // The value to load into FS when we change to kernel mode.
	uint gs;         // The value to load into GS when we change to kernel mode.
	uint ldt;        // Unused...
	ushort trap;
	ushort iomap_base;
}

static __gshared TSSEntry tss_entry;

// Initialise our task state segment structure.
static void WriteTSS(int num, ushort ss0, uint esp0)
{
	// Firstly, let's compute the base and limit of our entry into the GDT.
	uint base = cast(uint) &tss_entry;
	uint limit = base + TSSEntry.sizeof;

	// Now, add our TSS descriptor's address to the GDT.
	SetGDTGate(num, base, limit, 0xE9, 0x00);

	// Ensure the descriptor is initially zero.
	memset(&tss_entry, 0, TSSEntry.sizeof);

	tss_entry.ss0  = ss0;  // Set the kernel stack segment.
	tss_entry.esp0 = esp0; // Set the kernel stack pointer.

	// Here we set the cs, ss, ds, es, fs and gs entries in the TSS. These specify what
	// segments should be loaded when the processor switches to kernel mode. Therefore
	// they are just our normal kernel code/data segments - 0x08 and 0x10 respectively,
	// but with the last two bits set, making 0x0b and 0x13. The setting of these bits
	// sets the RPL (requested privilege level) to 3, meaning that this TSS can be used
	// to switch to kernel mode from ring 3.
	tss_entry.cs   = 0x0b;
	tss_entry.ss = tss_entry.ds = tss_entry.es = tss_entry.fs = tss_entry.gs = 0x13;
}

void set_kernel_stack(uint stack)
{
	tss_entry.esp0 = stack;
}
