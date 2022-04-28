// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.syscall;
import kernel.isr;
import kernel.console;
import kernel.common : panic;
import kernel.paging : alloc_frame, getPage, currentDirectory;
import leaf.syscall;

extern(C)
static string toString(uint reg, int len) @trusted
{
	char *p = cast(char *) reg;
	char[] ret;
	
	ret = p[0..len];
	return cast(string) ret;
}

alias size_t = uint;
alias off_t = uint;

extern(C)
static void *mmap(void *addr, size_t length, int prot, int flags,
	int fd, off_t offset)
{
	for (void *p = addr; length > 0; p += 4096) {
		alloc_frame(getPage(cast(uint) p, 1, currentDirectory), 0, 1);
		length -= 4096; /* FIXME: underflow. */
	}
	return null;
}

extern(C)
void SyscallHandler(ISRRegisters regs) @system
{
	//printk("syscall\n");
	switch(regs.eax) {
		case SyscallID.SYS_PRINT:
		printk(toString(regs.ebx, regs.ecx));
		break;

		case SyscallID.SYS_MMAP:
		printk("mmap\n");
		mmap(cast(void *) regs.ebx, cast(size_t) regs.ecx, 0, 0, 0, 0);
		printk("mmap done\n");
		break;
		
		default:
		printk("Unhandled syscall.");
		panic();
	}
}
