// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.common;
import kernel.tty;
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
@live void memset(scope void *dest, ubyte val, uint len)
{
	ubyte *temp = cast(ubyte *)dest;
	for (int i = 0; i < len; i++) {
		temp[i] = val;
	}
}

extern(C)
@live void memcpy(scope void *dest, scope const void *src, uint len)
{
	const(ubyte) *sp = cast(const(ubyte) *)src;
	ubyte *dp = cast(ubyte *)dest;
	for(; len != 0; len--) *dp++ = *sp++;
}

@safe @live void panic()
{
	DisableInterrupts();
	printk("PANIC!");
	for (;;) {
	}
}

@safe @live void ASSERT(bool cond) {
	if (cond == false) {
		printk("Assertation failed.");
		panic();
	}
}
