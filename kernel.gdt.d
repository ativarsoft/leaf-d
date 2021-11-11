// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.gdt;

extern(C)
struct GDTEntry
{
	align (1):
	ushort limit_low;
	ushort base_low;
	ubyte base_middle;
	ubyte access;
	ubyte granularity;
	ubyte base_high;
}

extern(C)
struct GDTPointer {
	align (1):
	ushort limit;
	uint base;
}

extern(C) void load_gdt(GDTPointer *p);

static __gshared GDTEntry[6] gdt;
static __gshared GDTPointer gdtPtr;

@trusted void SetGDTGate
	(uint entry,
	 uint base,
	 uint limit,
	 ubyte access,
	 ubyte granularity)
{
	gdt[entry].base_low = (base & 0xFFFF);
	gdt[entry].base_middle = (base >> 16) & 0xFF;
	gdt[entry].base_high = (base >> 24) & 0xFF;

	gdt[entry].limit_low = (limit & 0xFFFF);
	gdt[entry].granularity = (limit >> 16) & 0x0F; // limit high

	gdt[entry].granularity |= granularity & 0xF0; // flags
	gdt[entry].access = access;
}
