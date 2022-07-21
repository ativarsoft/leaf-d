// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.pit;
import kernel.console;
import kernel.tty;
import kernel.isr;
import kernel.common;
import kernel.task;

static __gshared int ticks = 0;

extern(C)
void TimerCallback(ISRRegisters regs)
{
	char[20] buf;
	ticks++;
	printk("Ticks: ");
	itoa(cast(char *) buf, 10, ticks);
	printk(cast(string) buf);
	printk("\n");

	SwitchTask(&regs);
}

void InitializeTimer(uint frequency)
{
	RegisterInterruptHandler(32, &TimerCallback);
	
	uint divisor = 1193180 / frequency;
	
	WritePortByte(0x43, 0x36); // Set PIT to repeating mode
	
	ubyte low = cast(ubyte)(divisor & 0xFF);
	ubyte high = cast(ubyte)((divisor >> 8) & 0xFF);
	
	WritePortByte(0x40, low);
	WritePortByte(0x40, high);
}
