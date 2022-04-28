module kernel.init;
import kernel.console;
import kernel.common;
import kernel.syscall;
import leaf.compiler;
import leaf.syscall;

extern(C)
void init() @safe
{
	user_print("Hello from userland!\n");
	user_print("Compiling file...\n");
	if (compile() == 0)
		user_print("Compilation successful.\n");
	else
		user_print("Failed to compile.\n");
	for (;;) {}
}
