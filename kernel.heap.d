module kernel.heap;
import kernel.console;
import kernel.heap;
import kernel.orderedlist;
import kernel.paging;
import kernel.common;
import kernel.memorystream;

enum KHEAP_START         = 0xC0000000;
enum KHEAP_INITIAL_SIZE  = 0x200000; // !!! It must be greater than the size of the index * type_t sizeof

enum HEAP_INDEX_SIZE   = 0x20000;
enum HEAP_MAGIC        = 0x123890AB;
enum HEAP_MIN_SIZE     = 0x70000;

//extern(C) extern static const __gshared uint end;
static __gshared uint heap;
static __gshared uint placement_address = 0;

struct Heap {
	OrderedArray index;
	uint startAddress;
	uint endAddress;
	uint maxAddress;
	ubyte supervisor;
	ubyte readOnly;
	MemoryStream stream;
}

static __gshared Heap *kheap = null;

void InitializeHeap()
{
	//placement_address = cast(uint)&end;
	placement_address = cast(uint) heap;
}

void asdf()
{
    for (int i = KHEAP_START; i < KHEAP_START+KHEAP_INITIAL_SIZE; i += 0x1000)
        getPage(i, 1, kernelDirectory);
}

extern(C)
void InitializeHeap2()
{
	if ((Header.sizeof != 3*4) || (Footer.sizeof != 2*4)) {
		printk("Incorrect struct sizes\n");
		panic();
	}
	
	// Now allocate those pages we mapped earlier.
	for (int i = KHEAP_START; i < KHEAP_START+KHEAP_INITIAL_SIZE; i += 0x1000)
		alloc_frame(getPage(i, 1, kernelDirectory), 0, 0);
	kheap = CreateHeap
		(KHEAP_START,
		 KHEAP_START + KHEAP_INITIAL_SIZE,
		 0xCFFFF000,
		 0,
		 0);
}

static byte header_t_less_than(type_t a, type_t b)
{
	kheap.stream.fseek(a, Origin.SEEK_SET);
	Header headerLeft = readHeader(kheap.stream);
	kheap.stream.fseek(b, Origin.SEEK_SET);
	Header headerRight = readHeader(kheap.stream);
    return headerLeft.size < headerRight.size? 1 : 0;
}

extern(C)
private Heap *CreateHeap(uint start, uint endAddress, uint max, ubyte supervisor, ubyte readOnly)
{
	Heap *heap = cast(Heap*)kmalloc(Heap.sizeof);
	//heap.stream = cast(MemoryStream) kmalloc(MemoryStream.sizeof);
	heap.stream = MemoryStream.newInstance(cast(void *) start, cast(uint) (endAddress - start));
	
	assert(start % 0x1000 == 0);
	assert(endAddress % 0x1000 == 0);
	
	// !!! The tutorial defines but doesn't call this function
	heap.index = create_ordered_array(HEAP_INDEX_SIZE, &header_t_less_than);

	heap.index = place_ordered_array(cast(void *) heap.index.array, HEAP_INDEX_SIZE, &header_t_less_than);
	
	// Shift the start address forward to resemble where we can start putting data.
    //start += type_t.sizeof * HEAP_INDEX_SIZE;
    
    uint size = cast(uint) (endAddress - start) - Header.sizeof - Footer.sizeof;

	// Make sure the start address is page-aligned.
	/*if ((start & 0xFFFFF000) != 0) {
		start &= 0xFFFFF000;
		start += 0x1000;
		size -= 0x1000;
	}*/
	// Write the start, end and max addresses into the heap structure.
	heap.startAddress = start;
	heap.endAddress = endAddress;
	heap.maxAddress = max;
	heap.supervisor = supervisor;
	heap.readOnly = readOnly;
	
	Header holeHeader;
	holeHeader.size = size;
	holeHeader.magic = HEAP_MAGIC;
	holeHeader.isHole = true;
	heap.stream.fseek(heap.startAddress - KHEAP_START, Origin.SEEK_SET);
	writeHeader(heap.stream, holeHeader);
	
	insert_ordered_array(heap.startAddress - KHEAP_START, heap.index);
	
	/*char[20] buf;
	kheap.stream.fseek(0, Origin.SEEK_SET);
	Header header = readHeader(kheap.stream);
	printk(&default_console, "???????????? header.magic: ");
    itoa(cast(char *) buf, 'x', cast(uint) header.magic);
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");*/
	
	return heap;
}

@system private void *AllocateInternal(uint sz, int _align, uint *phys)
{
	if (kheap == null) {
		// Placement allocation
		if (_align == 1 && (placement_address > 0x1000)) {
			placement_address &= 0xFFFFF000;
			placement_address += 0x1000;
		}
		if (phys) {
			*phys = placement_address;
		}
		uint tmp = placement_address;
		placement_address += sz;
		
		return cast(void *) tmp;
	}
	
	void *virtualAddr = Allocate(sz, cast(ubyte)_align, *kheap);
	if (phys != null) {
		// !!! get the page entry with the physical address.
		// !!! page contains the high 20 bits of the frame address in physical memory.
		page_t *page = getPage(cast(uint) virtualAddr, 0, kernelDirectory);
		// !!! get the frame (high physical address) from the page entry
		// !!! get the offset from the start of the virtual page
		// !!! from 0..0x1000 (maximum address)
		*phys = (*page >> 12) + (cast(uint) virtualAddr & 0xFFF);
	}
	return virtualAddr;
}

void *kmalloc_a(uint sz)
{
	return AllocateInternal(sz, 1, null);
}

void *kmalloc_p(uint sz, uint *phys)
{
	return AllocateInternal(sz, 0, phys);
}

void *kmalloc_ap(uint sz, uint *phys)
{
	return AllocateInternal(sz, 1, phys);
}

@trusted void *kmalloc(uint sz)
{
	return AllocateInternal(sz, 0, null);
}

struct Header
{
	align (4):
    uint magic;
    bool isHole;
    uint size;
};

struct Footer
{
	align (4):
    uint magic;
	uint headerAbsolutePosition;
};

private static void Expand(uint new_size, ref Heap heap)
{
}

extern(C)
private void *Allocate(uint size, int page_align, ref Heap heap)
{
	char[20] buf;
	
	heap.stream.fseek(0, Origin.SEEK_SET);
	Header header = readHeader(heap.stream);
	printk(&default_console, "!!!!!!!!!!!! header.magic: ");
    itoa(cast(char *) buf, 'x', cast(uint) header.magic);
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");
	
	uint sizeWithHeaders = size + Header.sizeof + Footer.sizeof;
	int iterator = FindSmallestHole(sizeWithHeaders, page_align != 0? 1 : 0, heap);
	if (iterator == -1) { // TODO: no free space
		printk(&default_console, "ERROR: no free space.\n");
		panic();
	}

	printk(&default_console, "iterator: ");
    itoa(cast(char *) buf, 'x', cast(uint) iterator);
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");

	if (!(iterator < heap.index.size)) {
		printk(&default_console, "ERROR: Iterator is not less then heap index size.\n");
		panic();
	}
	uint headerOffset = heap.index.array[iterator];
	
	heap.stream.fseek(headerOffset, Origin.SEEK_SET);
	Header originalHoleHeader = readHeader(heap.stream);
	uint originalHolePosition = headerOffset;
	uint originalHoleSize = originalHoleHeader.size;
	if (header.magic != HEAP_MAGIC) {
		printk("Incorrect hole header magic.\n");
		panic();
	}
	
	// Split the hole?
	// If the remaining size if less than the headers overhead for a new
	// hole then just expand the new hole to the old hole size.
	if (originalHoleSize - size < Header.sizeof + Footer.sizeof) {
		size += originalHoleSize - size;
		sizeWithHeaders = originalHoleSize + Header.sizeof + Footer.sizeof;
	}
	
	// Page align? Make a new hole in the front
	if (false) {
	} else {
		// We don't need this hole.
		remove_ordered_array(iterator, heap.index);
	}
	
	// Overwrite original header.
	Header newHeader;
	newHeader.magic = HEAP_MAGIC;
	newHeader.isHole = false;
	newHeader.size = size;
	heap.stream.fseek(headerOffset, Origin.SEEK_SET);
	writeHeader(heap.stream, newHeader);
	Footer newFooter;
	newFooter.magic = HEAP_MAGIC;
	newFooter.headerAbsolutePosition = headerOffset;
	heap.stream.fseek(size, Origin.SEEK_CUR);
	writeFooter(heap.stream, newFooter);
	
	/* Size of the new hole block. */
	uint newSizeWithHeaders = size + Header.sizeof + Footer.sizeof;
	
	printk(&default_console, "originalHoleHeader.size - newSizeWithHeaders: ");
    itoa(cast(char *) buf, 'x', cast(uint) originalHoleHeader.size - newSizeWithHeaders);
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");
	
	if (originalHoleHeader.size - size > Header.sizeof + Footer.sizeof) {
		uint newHolePosition = originalHolePosition + size + Header.sizeof + Footer.sizeof;
		
		printk("originalHolePosition: ");
		PrintIntHex(originalHolePosition);
		printk("\nnewHolePosition: ");
		PrintIntHex(newHolePosition);
		printk("\n");
		
		heap.stream.fseek(newHolePosition, Origin.SEEK_SET);
		Header newHoleHeader;
		newHoleHeader.magic = HEAP_MAGIC;
		newHoleHeader.isHole = true;
		newHoleHeader.size = (originalHoleSize - Header.sizeof - Footer.sizeof) - size;
		writeHeader(heap.stream, newHoleHeader);
		
		Footer newHoleFooter;
		newHoleFooter.magic = HEAP_MAGIC;
		newHoleFooter.headerAbsolutePosition = heap.stream.ftell() - Header.sizeof;
		heap.stream.fseek(newHoleHeader.size, Origin.SEEK_CUR);
		writeFooter(heap.stream, newHoleFooter);
		
		insert_ordered_array(newHolePosition, heap.index);
	}
	
	heap.stream.fseek(originalHolePosition, Origin.SEEK_SET);
	return heap.stream.getAddress() + Header.sizeof;
}

@trusted void getHeaderFromIndex(int i, ref OrderedArray oa) {
}

@safe Header readHeader(ref MemoryStream stream) {
	Header header;
	header.magic = stream.readUInt();
	header.isHole = cast(bool) stream.readUInt();
	header.size = stream.readUInt();
	return header;
}

@safe void writeHeader
	(ref MemoryStream stream,
	 ref Header header)
{
	stream.writeUInt(header.magic);
	stream.writeUInt(header.isHole? 1 : 0);
	stream.writeUInt(header.size);
}

@safe Footer readFooter(ref MemoryStream stream) {
	Footer footer;
	footer.magic = stream.readUInt();
	footer.headerAbsolutePosition = stream.readUInt();
	return footer;
}

@safe void writeFooter
	(ref MemoryStream stream,
	 ref Footer footer)
{
	stream.writeUInt(footer.magic);
	stream.writeUInt(footer.headerAbsolutePosition);
}

/*@safe*/ private int FindSmallestHole(uint size, bool pageAlign, ref Heap heap)
{
	char[20] buf;
	int i;

	for (i = 0; i < heap.index.size; i++) {
		/* requires @system */
		//header_t *header = (header_t *)lookup_ordered_array(iterator, &heap->index);
		assert(i < heap.index.size);
		uint headerOffset = heap.index.array[i];

		heap.stream.fseek(headerOffset, Origin.SEEK_SET);
		Header header = readHeader(heap.stream);

		if (pageAlign == true) {
			int dataSize = header.size;
			//int alignOffset = 0x1000 + ((heap.stream.ftell() + Header.sizeof) % 0x1000);
			if (heap.stream.ftell() > 0) {
				uint displacement;
				// Get the remaining distance we have to seek to
				// get to the next aligned address.
				// First get the displacement from the start of the page
				// then get the remaining distance to the next page by
				// subtracting from the total page size.
				displacement = 0x1000 - (heap.stream.ftell() % 0x1000);
				// Subtract the displacement from the total hole size.
				dataSize = header.size - displacement;
			}
			if (size <= dataSize)
				break;
		} else if (size <= header.size) {
			break;
		}
		printk(&default_console, "header.size: ");
    itoa(cast(char *) buf, 'x', cast(uint) header.size);
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");
	}
	
	printk("$$$$$$$$$$$$$$$$ heap.index.array[i]: ");
	PrintIntHex(heap.index.array[i]);
	printk("\n");
	
	if (i == heap.index.size)
		return -1;
	return i;
}

private void Free(int offset, ref Heap heap)
{
	/*char[20] buf;
	heap.stream.fseek(0, Origin.SEEK_SET);
	Header header = readHeader(heap.stream);
	printk(&default_console, "header.magic: ");
    itoa(cast(char *) buf, 'x', cast(uint) header.magic);
	printk(&default_console, cast(string) buf);
	printk(&default_console, "\n");*/
	
	Header header;
	int headerOffset = offset - Header.sizeof;
	heap.stream.fseek(headerOffset, Origin.SEEK_SET);
	header = readHeader(heap.stream);
	
	Footer footer;
	int footerOffset = offset + header.size;
	heap.stream.fseek(footerOffset, Origin.SEEK_SET);
	footer = readFooter(heap.stream);
	
	
	if (header.magic != HEAP_MAGIC) {
		printk(&default_console, "ERROR: Free: header magic is incorrect.");
		panic();
	}
    if (footer.magic != HEAP_MAGIC) {
		printk(&default_console, "ERROR: Free: footer magic is incorrect.");
		panic();
	}
	
	header.isHole = true;
	heap.stream.fseek(headerOffset, Origin.SEEK_SET);
	writeHeader(heap.stream, header);
	
	footer.headerAbsolutePosition = headerOffset;
	heap.stream.fseek(footerOffset, Origin.SEEK_SET);
	writeFooter(heap.stream, footer);
	
	bool doAdd = true;
	
	if (doAdd == true)
		insert_ordered_array(headerOffset, heap.index);
}

private static uint Contract(uint new_size, ref Heap heap)
{
	return 0;
}

void kfree(void *p)
{
	int offset = cast(int) (p - KHEAP_START);
	Free(offset, *kheap);
}

void DumpHeap(ref Heap heap)
{
	char[20] buf;
	heap.stream.fseek(0, Origin.SEEK_SET);
	while (heap.stream.ftell() < heap.stream.data.length) {
		int headerPos = heap.stream.ftell();
		printk("Header found at position 0x");
		PrintIntHex(headerPos);
		printk(&default_console, "\n");
		Header header = readHeader(heap.stream);
		if (header.magic != HEAP_MAGIC) {
			printk("Incorrect header magic.\n");
			return;
		}
		printk("Is hole: ");
		PrintIntHex(header.isHole);
		printk(&default_console, "\n");

		heap.stream.fseek(header.size, Origin.SEEK_CUR);
		int footerPos = heap.stream.ftell();
		printk("Footer position 0x");
		PrintIntHex(footerPos);
		printk(&default_console, "\n");
		Footer footer = readFooter(heap.stream);
		if (footer.magic != HEAP_MAGIC) {
			printk("Incorrect footer magic.\n");
			return;
		}
		if (footer.headerAbsolutePosition != headerPos) {
			printk("Incorrect header position on the footer.\n");
			return;
		}
	}
}

extern(C)
void DumpIndex(ref Heap heap) {
	for (int i = 0; i < heap.index.size; i++) {
		printk("Index entry found: ");
		PrintIntHex(heap.index.array[i]);
		printk("\n");
	}
}
