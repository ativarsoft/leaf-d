module kernel.pit;
import kernel.console;
import kernel.isr;
import kernel.common;

static __gshared int ticks = 0;

void TimerCallback(ISRRegisters regs)
{
	char[20] buf;
	ticks++;
	printk(&default_console, "Ticks: ");
	itoa(cast(char *) buf, 10, ticks);
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");
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
