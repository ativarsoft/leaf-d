// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.idt;

struct IDTDescr {
	align (1):
	ushort offset_1; // offset bits 0..15
	ushort selector; // a code segment selector in GDT or LDT
	ubyte zero;      // unused, set to 0
	ubyte type_attr; // type and attributes, see below
	ushort offset_2; // offset bits 16..31
};

struct IDTPointer {
	align (1):
	ushort limit;
	uint base;
}

extern(C) {
	void load_idt(IDTPointer *p);
	void EnableInterrupts();
	void DisableInterrupts();
}

//extern(C) extern __gshared IDTDescr[256] idt;
static __gshared IDTDescr[256] idt;
static __gshared IDTPointer idtPtr;

extern(C) {
	void isr0();
	void isr1();
	void isr2();
	void isr3();
	void isr4();
	void isr5();
	void isr6();
	void isr7();
	void isr8();
	void isr9();
	void isr10();
	void isr11();
	void isr12();
	void isr13();
	void isr14();
	void isr15();
	void isr16();
	void isr17();
	void isr18();
	void isr19();
	void isr20();
	void isr21();
	void isr22();
	void isr23();
	void isr24();
	void isr25();
	void isr26();
	void isr27();
	void isr28();
	void isr29();
	void isr30();
	void isr31();

	void isr32();
	void isr33();
	void isr34();
	void isr35();
	void isr36();
	void isr37();
	void isr38();
	void isr39();
	void isr40();
	void isr41();
	void isr42();
	void isr43();
	void isr44();
	void isr45();
	void isr46();
	void isr47();
}

void SetIDTGate(ubyte num, uint base, ushort selector, ubyte flags)
{
	idt[num].offset_1 = base & 0xFFFF;
	idt[num].offset_2 = (base >> 16) & 0xFFFF;

	idt[num].selector = selector;
	idt[num].zero = 0;
	idt[num].type_attr = flags;
}
