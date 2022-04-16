// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.syscall;
import kernel.isr;
import kernel.console;

extern(C) {
	enum numSyscalls = 2;

	void sys_print(string s);
}

@live void SyscallHandler(ISRRegisters regs)
{
	printk("syscall\n");
}
