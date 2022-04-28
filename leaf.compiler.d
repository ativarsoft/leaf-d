module leaf.compiler;
import leaf.syscall;
import kernel.memorystream;
import kernel.common;

extern(C):

/**********************
 * QUICK HACKS *
 **********************/

MemoryStream newMemoryStreamUser(void **heap, void *p, uint len) {
	//MemoryStream model = scoped!MemoryStream;
	auto size = __traits(classInstanceSize, MemoryStream);
	MemoryStream cls = cast(MemoryStream) malloc(heap, size);
	//cls.__ctor();
	//panic();
	//memcpy(cast(void *) cls, cast(void *) model, size);
	memset(cast(void *) cls, 0, size);
	
	ubyte *tmp = cast(ubyte *) p;
	//cls.data = tmp[0..len];
	cls.data = tmp[0..len];
	//cls.position = 0;
	cls.position = 0;
	//panic();
	return cls;
}

enum HEAP_START = 0xA0000000;

static __gshared void *compiler_heap;

void *malloc(void **heap, uint size) @system
{
	void *p = *heap;
	*heap += size;
	return p;
}

void free(void *p) @system
{
	// Do nothing...
}

enum BUFFER_SIZE = 1024;

struct FILE {
	ubyte[] buffer;
	MemoryStream stream;
};

int getchar(FILE *file) @trusted
{
	return 0;
}

FILE *open(void **heap) @trusted
{
	FILE *file = cast(FILE *) malloc(heap, FILE.sizeof);
	ubyte *temp = cast(ubyte *) malloc(heap, BUFFER_SIZE);
	file.buffer = temp[0..BUFFER_SIZE];
	memset(file.buffer.ptr, 0, file.buffer.length);
	file.stream = newMemoryStreamUser(heap, file.buffer.ptr, file.buffer.length);
	return file;
}

int close(FILE *file) @trusted
{
	free(file);
	return 0;
}

/************************
 * THE COMPILER
 ************************/

enum Token {
	TAG_OPEN,
	TAG_CLOSE,
	IDENTIFIER,
	EOF
}

Token lex(FILE *file) @safe
{
	getchar(file);
	return Token.EOF;
}

int parse(FILE *file) @safe
{
	lex(file);
	return 0;
}

int compile() @trusted
{
	void *compiler_heap = cast(void *) HEAP_START;
	sys_mmap(cast(void *) HEAP_START, 4096);
	FILE *file = open(&compiler_heap);
	user_print("a\n");
	if (file == null)
		return 1;
	if (parse(file) != 0)
		return 2;
	if (close(file) != 0)
		return 3;
	return 0;
}
