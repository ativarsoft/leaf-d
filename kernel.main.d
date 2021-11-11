// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.main;
import core.bitop; // will be core.volatile in later gdc
import kernel.console;
import kernel.gdt;
import kernel.idt;
import kernel.pit;
import kernel.common;
import kernel.heap;
import kernel.paging;
import kernel.task;
import kernel.tss;
import kernel.syscall;
import kernel.isr;

extern(C) void enter_v86(uint ss, uint esp, uint cs, uint eip);
extern(C) int detect_v86();
extern(C++) {
	class Test {
		int a;
	}
}

static __gshared char test_char = 'D';

/*pragma(mangle, "_D14TypeInfo_Class6__vtblZ")
immutable void* horrible_hack = null; // D:*/

/*extern (C) void __assert(bool cond, const(char)[] msg) {
}*/

extern (C) void __assert(const(char)[] msg, const(char)[] filename, int line) {
	//cls(&default_console);
	if (filename != null) {
		printk(&default_console, cast(string) filename);
		printk(&default_console, ": ");
	}
	char[20] buf;
	itoa(cast(char *) buf, 'd', line);
	printk(&default_console, cast(string) buf);
	printk(&default_console, ": ");
	printk(&default_console, cast(string) msg);
	printk(&default_console, "\n");
}

extern(C) void main(uint magic, uint addr, uint stack, uint heap)
{
	// Multiboot version 2
	if (magic != 0x2BADB002) {
		printk(&default_console, "Incorrect magic.");
		panic();
	}
	if ((cast(uint) addr % 64) != 0) {
		printk(&default_console, "Address is not 64-bit aligned.");
		panic();
	}
	
	char[20] buf;
	
	kernel.heap.heap = heap;
	
	printk(&default_console, "end: ");
    itoa(cast(char *) buf, 'x', cast(uint) heap);
	printk(&default_console, cast(string) buf);
	printk(&default_console, "             \n");
	
	//panic();
	
	//if (cast(uint) addr & )
	string local = "local\n";
	//cons default_console = {0, 0, 80, 25, (cast(ubyte*)0xFFFF_8000_000B_8000)[0..80*25*2]};
	cls(&default_console);
	printk(&default_console, "Leaf v1.0\n");
	printk(&default_console, "Virtual 8086 Mode: ");
	if (detect_v86())
		printk(&default_console, "True\n");
	else
		printk(&default_console, "False\n");
	ubyte *vidmem = cast(ubyte*)0xFFFF_8000_000B_8000;
	test_char = 'A';
	vidmem[79 * 2] = test_char & 0xFF;
	vidmem[79 * 2 + 1] = 0x07;
	
	//char[20] buf;
	/*itoa(cast(char *) buf, 'd', cast(int) &default_console);
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");
	
	itoa(cast(char *) buf, 'd', cast(int) &test_char);
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");*/
	
	SetGDTGate(0, 0, 0, 0, 0);                //Null segment
	SetGDTGate(1, 0, 0xFFFFFFFF, 0x9A, 0xCF); //Code segment
	SetGDTGate(2, 0, 0xFFFFFFFF, 0x92, 0xCF); //Data segment
	SetGDTGate(3, 0, 0xFFFFFFFF, 0xFA, 0xCF); //User mode code segment
	SetGDTGate(4, 0, 0xFFFFFFFF, 0xF2, 0xCF); //User mode data segment
	WriteTSS(5, 0x10, 0x0);

	gdtPtr.limit = (GDTEntry.sizeof * 5) - 1;
	gdtPtr.base = cast(uint) &gdt;
	load_gdt(&gdtPtr);
	printk(&default_console, "GDT was set up successfully.\n");
	
	// Remap PIC
	WritePortByte(0x20, 0x11);
    WritePortByte(0xA0, 0x11);
    WritePortByte(0x21, 0x20);
    WritePortByte(0xA1, 0x28);
    WritePortByte(0x21, 0x04);
    WritePortByte(0xA1, 0x02);
    WritePortByte(0x21, 0x01);
    WritePortByte(0xA1, 0x01);
    WritePortByte(0x21, 0x0);
    WritePortByte(0xA1, 0x0);
    printk(&default_console, "PIC was remmaped successfully.\n");
    
    // Values too high freeze the emulator.
    // Values too low prints the message too quickly.
    //InitializeTimer(1193180);
	//InitializeTimer(10);
	printk(&default_console, "Enabled PIT.\n");
    
	// Initialize the uninitialized gates
	memset(cast(ubyte *) idt, 0, IDTDescr.sizeof * 256);
	
	SetIDTGate(0, cast(uint) &isr0, 0x08, 0x8E);
	SetIDTGate(1, cast(uint) &isr1, 0x08, 0x8E);
	SetIDTGate(2, cast(uint) &isr2, 0x08, 0x8E);
	SetIDTGate(3, cast(uint) &isr3, 0x08, 0x8E);
	SetIDTGate(4, cast(uint) &isr4, 0x08, 0x8E);
	SetIDTGate(5, cast(uint) &isr5, 0x08, 0x8E);
	SetIDTGate(6, cast(uint) &isr6, 0x08, 0x8E);
	SetIDTGate(7, cast(uint) &isr7, 0x08, 0x8E);
	SetIDTGate(8, cast(uint) &isr8, 0x08, 0x8E);
	SetIDTGate(9, cast(uint) &isr9, 0x08, 0x8E);
	SetIDTGate(10, cast(uint) &isr10, 0x08, 0x8E);
	SetIDTGate(11, cast(uint) &isr11, 0x08, 0x8E);
	SetIDTGate(12, cast(uint) &isr12, 0x08, 0x8E);
	SetIDTGate(13, cast(uint) &isr13, 0x08, 0x8E);
	SetIDTGate(14, cast(uint) &isr14, 0x08, 0x8E);
	SetIDTGate(15, cast(uint) &isr15, 0x08, 0x8E);
	SetIDTGate(16, cast(uint) &isr16, 0x08, 0x8E);
	SetIDTGate(17, cast(uint) &isr17, 0x08, 0x8E);
	SetIDTGate(18, cast(uint) &isr18, 0x08, 0x8E);
	SetIDTGate(19, cast(uint) &isr19, 0x08, 0x8E);
	SetIDTGate(20, cast(uint) &isr20, 0x08, 0x8E);
	SetIDTGate(21, cast(uint) &isr21, 0x08, 0x8E);
	SetIDTGate(22, cast(uint) &isr22, 0x08, 0x8E);
	SetIDTGate(23, cast(uint) &isr23, 0x08, 0x8E);
	SetIDTGate(24, cast(uint) &isr24, 0x08, 0x8E);
	SetIDTGate(25, cast(uint) &isr25, 0x08, 0x8E);
	SetIDTGate(26, cast(uint) &isr26, 0x08, 0x8E);
	SetIDTGate(27, cast(uint) &isr27, 0x08, 0x8E);
	SetIDTGate(28, cast(uint) &isr28, 0x08, 0x8E);
	SetIDTGate(29, cast(uint) &isr29, 0x08, 0x8E);
	SetIDTGate(30, cast(uint) &isr30, 0x08, 0x8E);
	SetIDTGate(31, cast(uint) &isr31, 0x08, 0x8E);
	
	/* IRQs */
	SetIDTGate(32, cast(uint) &isr32, 0x08, 0x8E);
	SetIDTGate(33, cast(uint) &isr33, 0x08, 0x8E);
	SetIDTGate(34, cast(uint) &isr34, 0x08, 0x8E);
	SetIDTGate(35, cast(uint) &isr35, 0x08, 0x8E);
	SetIDTGate(36, cast(uint) &isr36, 0x08, 0x8E);
	SetIDTGate(37, cast(uint) &isr37, 0x08, 0x8E);
	SetIDTGate(38, cast(uint) &isr38, 0x08, 0x8E);
	SetIDTGate(39, cast(uint) &isr39, 0x08, 0x8E);
	SetIDTGate(40, cast(uint) &isr40, 0x08, 0x8E);
	SetIDTGate(41, cast(uint) &isr41, 0x08, 0x8E);
	SetIDTGate(42, cast(uint) &isr42, 0x08, 0x8E);
	SetIDTGate(43, cast(uint) &isr43, 0x08, 0x8E);
	SetIDTGate(44, cast(uint) &isr44, 0x08, 0x8E);
	SetIDTGate(45, cast(uint) &isr45, 0x08, 0x8E);
	SetIDTGate(46, cast(uint) &isr46, 0x08, 0x8E);
	SetIDTGate(47, cast(uint) &isr47, 0x08, 0x8E);
	
	RegisterInterruptHandler(80, &SyscallHandler);
	
	idtPtr.limit = (IDTDescr.sizeof * 255) - 1;
	idtPtr.base = cast(uint) &idt;
	load_idt(&idtPtr);
	printk(&default_console, "IDT was set up successfully.\n");
	
	/*uint zero = 0;
	uint division_by_zero = 1/zero;
	printk(&default_console, "Returned from ISR.\n");*/
	
	// generate an exception
	/*ubyte[] m = get_vidmem_slice(&default_console);
	ubyte out_of_bounds = m[5000];*/
	
	InitializeHeap();
	printk(&default_console, "Initialized heap.\n");
	EnableInterrupts();
	printk(&default_console, "Enabled interrupts.\n");
	InitializePaging(stack);
	printk(&default_console, "Enabled paging.\n");
	/*InitializeHeap2();
	printk(&default_console, "Initialized heap 2.\n");*/
	
	/*printk(&default_console, "Allocating first block.\n");
	uint *a = cast(uint*) kmalloc(8);
	*a = 0;
	printk(&default_console, "Allocating second block.\n");
	uint *b = cast(uint*) kmalloc(8);
	*b = 0;
	printk(&default_console, "Freeing first block.\n");
	kfree(a);
	printk(&default_console, "Freeing second block.\n");
	kfree(b);
	printk(&default_console, "Allocating third block.\n");
	uint *c = cast(uint *) kmalloc(12);
	printk(&default_console, "Freeing third block.\n");
	kfree(c);*/
	
	InitializeTasking(stack);
	printk(&default_console, "Initialized the stack successfuly.\n");
	
	// Create a new process in a new address space which is a clone of this.
    int ret = fork();
    
	printk(&default_console, "fork() returned ");
    itoa(cast(char *) buf, 'd', ret);
	printk(&default_console, cast(string) buf);
    printk(&default_console, ", and getpid() returned ");
    itoa(cast(char *) buf, 'd', getpid());
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");
	
	InitializeHeap2();
	printk(&default_console, "Initialized heap 2.\n");
	
	printk(&default_console, "Allocating first block.\n");
	uint *a = cast(uint*) kmalloc(4);
	printk("a positon: ");
	PrintIntHex(cast(int) a);
	printk("\n");
	*a = 0xdeadb33f;
	//DumpHeap(*kheap);
	printk(&default_console, "Allocating second block.\n");
	uint *b = cast(uint*) kmalloc(4);
	*b = 0xdeadb33f;
	//DumpHeap(*kheap);
	kfree(a);
	//DumpIndex(*kheap);
	//panic();
	//DumpHeap(*kheap);
	uint *c = cast(uint*) kmalloc(32);
	*c = 0xdeadb33f;
	kfree(b);
	kfree(c);

	printk(&default_console, local);
    
	for (;;) {
	}
}

/*extern(C) void _d_arraybounds(string file, uint line)
{
	//onRangeError(file, line);
	for(;;) {
	}
}*/
