// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.common;
import kernel.console;
import kernel.idt;

extern(C) {
	@safe ubyte ReadPortByte(ushort portAddr);
	@safe ushort ReadPortWord(ushort portAddr);
	@safe uint ReadPortLong(ushort portAddr);
	
	@safe void WritePortByte(ushort portAddr, ubyte portValue);
	@safe void WritePortWord(ushort portAddr, ushort portValue);
	@safe void WritePortLong(ushort portAddr, uint portValue);
	
	@safe void FlushTLB();
	@safe uint ReadEIP();
	@safe void CopyPagePhysical(uint, uint); // !!! prototype was missing
}

/*void memset(void *dest, ubyte val, uint len)
{
    ubyte *temp = cast(ubyte *)dest;
    for ( ; len != 0; len--) *temp++ = val;
}*/

extern(C)
void memset(void *dest, ubyte val, uint len)
{
    ubyte *temp = cast(ubyte *)dest;
    for (int i = 0; i < len; i++) {
		temp[i] = val;
	}
}

extern(C)
void memcpy(void *dest, const void *src, uint len)
{
    const(ubyte) *sp = cast(const(ubyte) *)src;
    ubyte *dp = cast(ubyte *)dest;
    for(; len != 0; len--) *dp++ = *sp++;
}

/*void memcpy(ubyte *dest, const(ubyte) *src, uint len)
{
	char[20] buf; // !!!
    const(ubyte) *sp = cast(const(ubyte) *)src;
    ubyte *dp = cast(ubyte *)dest;
    printk(&default_console, "2badb002: ");
	itoa(cast(char *) buf, 'x', cast(uint) *(cast(uint *) (cast(uint) sp + len - 12)));
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");
    for(int i = 0; i < len; i++) { // !!!
		//printk(&default_console, ".");
		//printk(&default_console, "i: ");
	//itoa(cast(char *) buf, 'x', cast(uint) dp);
	//printk(&default_console, cast(string) buf);
	//printk(&default_console, "\n");
		dp[i] = sp[i];
	dp++;
	sp++;
	}
	//printk(&default_console, "2badb002 2: ");
	//itoa(cast(char *) buf, 'x', cast(uint) *(cast(uint *) (cast(uint) sp + len - 12)));
	//printk(&default_console, cast(string) buf);
	//printk(&default_console, "\n");
	
	printk(&default_console, "\n");
}*/

@trusted void panic()
{
	DisableInterrupts();
	printk(&default_console, "PANIC!");
	for (;;) {
	}
}

void ASSERT(bool cond) {
	if (cond == false) {
		printk(&default_console, "Assertation failed.");
		panic();
	}
}
