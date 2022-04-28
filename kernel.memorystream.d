// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.memorystream;
import kernel.common;
import kernel.heap;
import kernel.console;

enum Origin {
	SEEK_SET,	// Beginning of file
	SEEK_CUR,	// Current position of the file
	SEEK_END	// End of file
}

extern(C++) class MemoryStream {
	extern(C) ubyte[] data;
	extern(C) int position;

	public static MemoryStream newInstance(void *p, uint len) {
		//MemoryStream model = scoped!MemoryStream;
		auto size = __traits(classInstanceSize, MemoryStream);
		MemoryStream cls = cast(MemoryStream) kmalloc(size);
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
	
	@trusted public final void writeUInt(uint x) {
		data[position+0] = (x >> 0) & 0xFF;
		data[position+1] = (x >> 8) & 0xFF;
		data[position+2] = (x >> 16) & 0xFF;
		data[position+3] = (x >> 24) & 0xFF;
	
		position += 4;
	}
	
	@trusted public final uint readUInt() {
		uint x;
		x |= data[position+0] << 0;
		x |= data[position+1] << 8;
		x |= data[position+2] << 16;
		x |= data[position+3] << 24;

		position += 4;
		return x;
	}
	
	@trusted public final uint ftell() {
		return position;
	}
	
	@trusted public final void fseek(int newPosition, int origin) {
		switch (origin) {
			case Origin.SEEK_SET:
			assert(newPosition < data.length);
			assert(newPosition >= 0);
			position = newPosition;
			break;
			
			case Origin.SEEK_CUR:
			assert(newPosition + position < data.length);
			assert(newPosition + position >= 0);
			position += newPosition;
			break;
			
			case Origin.SEEK_END:
			assert(newPosition + position < data.length);
			assert(newPosition + position >= 0);
			position = data.length;
			break;
			
			default:
			assert(0);
		}
	}
	
	@trusted public final void *getAddress() {
		return &data[position];
	}
}
