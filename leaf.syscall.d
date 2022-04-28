module leaf.syscall;

public:
enum SyscallID {
	SYS_PRINT = 69,
	SYS_MMAP = 1
}

extern(C) {
	enum numSyscalls = 2;

	void sys_print(immutable(char) *s, int length);
	void *sys_mmap(void *addr, uint length);
}

@trusted user_print(string s)
{
	sys_print(s.ptr, s.length);
}
