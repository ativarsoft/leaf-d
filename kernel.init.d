module kernel.init;
import kernel.console;
import kernel.common;
import kernel.syscall;

extern(C)
void init()
{
	sys_print("Hello from userland!");
	for (;;) {}
}
