// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.isr;
import kernel.console;
import kernel.tty;
import kernel.common;

alias isr_t = extern(C) void function(ISRRegisters);

extern(C)
struct ISRRegisters
{
	align (1):
    uint ds;
    uint edi, esi, ebp, esp, ebx, edx, ecx, eax;
    uint int_no, err_code;
    uint eip, cs, eflags, useresp, ss;
};

extern(C) {
	static __gshared int count = 0;
	static __gshared isr_t[256] interrupt_handlers;
}

extern(C)
void RegisterInterruptHandler(ubyte n, isr_t handler)
{
    interrupt_handlers[n] = handler;
}

extern(C)
void isrHandler(ISRRegisters regs)
{
	if (regs.int_no < 32) {
		char[20] buf;
		itoa(cast(char *) buf, 'd', cast(int) regs.int_no);
		printk("Interrupt ");
		printk(cast(string) buf);
		printk(". ");
		
		itoa(cast(char *) buf, 'd', cast(int) regs.eax);
		printk("EAX ");
		printk(cast(string) buf);
		printk(". ");
		
		itoa(cast(char *) buf, 'd', cast(int) regs.err_code);
		printk("Error code ");
		printk(cast(string) buf);
		printk(".\n");
		
		if (regs.int_no == 14)
			panic();

		if (regs.int_no == 13)
			panic();
	} else {
		char[20] buf;
		itoa(cast(char *) buf, 'd', cast(int) regs.int_no);
		printk("Interrupt ");
		printk(cast(string) buf);
		printk(". ");
		count += 1;

		if (regs.int_no >= 40) {
			// Send reset signal to slave.
			WritePortByte(0xA0, 0x20);
		}
		// Send reset signal to master. (As well as slave, if necessary).
		WritePortByte(0x20, 0x20);

		if (cast(int) interrupt_handlers[regs.int_no] != 0) {
			isr_t handler = interrupt_handlers[regs.int_no];
			handler(regs);
		}
	}
}
