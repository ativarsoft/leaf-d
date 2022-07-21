// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.paging;
import kernel.heap;
import kernel.common;
import kernel.tty;
import kernel.task; // debug

alias page_t = uint;
static __gshared uint PAGE_FRAME_MASK = 0xFFFFF000U;

struct PageTable {
	page_t[1024] pages;
}

struct PageDirectory {
	PageTable*[1024] tables;
	uint[1024] tablesPhysical;
	uint physicalAddr;
}

extern(C) void EnablePaging(uint *);

static __gshared PageDirectory *kernelDirectory = null;
static __gshared PageDirectory *currentDirectory = null;

/* Look up the theory to understand the bit magic. */
static __gshared uint *frames;
static __gshared uint nframes;
	
uint INDEX_FROM_BIT(uint a) {
	return a/(8*4);
}

uint OFFSET_FROM_BIT(uint a) {
	return a%(8*4);
}

void setFrame(uint frame_addr) {
	uint frame = frame_addr / 0x1000;
	uint idx = INDEX_FROM_BIT(frame);
	uint off = OFFSET_FROM_BIT(frame);
	frames[idx] |= (0x1 << off);
}

void clearFrame(uint frame_addr) {
	uint frame = frame_addr / 0x1000;
	uint idx = INDEX_FROM_BIT(frame);
	uint off = OFFSET_FROM_BIT(frame);
	frames[idx] &= ~(0x1 << off);
}

uint testFrame(uint frame_addr) {
	uint frame = frame_addr / 0x1000;
	uint idx = INDEX_FROM_BIT(frame);
	uint off = OFFSET_FROM_BIT(frame);
	return (frames[idx] & (0x1 << off));
}

uint firstFreeFrame() {
	for (int i = 0; i < INDEX_FROM_BIT(nframes); i++) {
		for (int j = 0; j < 32; j++) {
			uint bitToTest = 0x1 << j;
			if (!(frames[i]&bitToTest)) {
				return i * 4 * 8 + j;
			}
		}
	}
	assert(0);
}

// Function to allocate a frame.
void alloc_frame(page_t *page, int is_kernel, int is_writeable)
{
	//printk(&default_console, "Alloc frame.\n");
	if ((((*page >> 12) & 0xFFFFF) != 0) && false) {
		printk("Page already taken.\n");
		return;
	} else {
		uint idx = firstFreeFrame();
		if (idx == cast(uint)-1) {
			// PANIC! no free frames!!
			printk("ERROR: No free frames!\n");
			panic();
		}
		setFrame(idx*0x1000);
		*page |= 1 << 0; // Present
		*page |= (is_writeable)? 1 << 1 : 0;
		*page |= (is_kernel)? 0 : 1 << 2;
		*page |= idx << 12; // 0x1000, 0x2000, 0x3000 ...
	}
}

void InitializePaging(uint stack)
{
	char[20] buf; // !!!
	uint mem_end_page = 0x1000000;
    
    nframes = mem_end_page / 0x1000;
    frames = cast(uint*)kmalloc(INDEX_FROM_BIT(nframes));
    memset(frames, 0, INDEX_FROM_BIT(nframes));
    
    kernelDirectory = cast(PageDirectory*)kmalloc_a(PageDirectory.sizeof);
    currentDirectory = kernelDirectory;
    
    memset(kernelDirectory, 0, PageDirectory.sizeof); // !!!
    
    for (int i = 0; i < 1024; i++)
		kernelDirectory.tables[i] = null;
    
    asdf();
	
    // Alloc pages for the heap and for the kernel
    for (int i = 0; i < placement_address + KHEAP_INITIAL_SIZE; i += 0x1000) { // !!!
			alloc_frame(getPage(i, 1, kernelDirectory), 0, 0); // !!! is_writable
	}

	EnablePaging(cast(uint *) kernelDirectory.tablesPhysical);
}

page_t *getPage(uint address, int make, PageDirectory *dir)
{
    // Turn the address into an index.
    address /= 0x1000;
    // Find the page table containing this address.
    uint table_idx = address / 1024;
	
    if (dir.tables[table_idx]) {
        return &dir.tables[table_idx].pages[address%1024];
    } else if(make) {
        uint tmp;
        dir.tables[table_idx] = cast(PageTable*)kmalloc_ap(PageTable.sizeof, &tmp);
        memset(dir.tables[table_idx], 0, PageTable.sizeof); // !!!
        dir.tablesPhysical[table_idx] = tmp | 0x7; // PRESENT, RW, US.
        return &dir.tables[table_idx].pages[address%1024];
    } else {
        return null;
    }
}

// Function to deallocate a frame.
void free_frame(page_t *page)
{
    uint frame = ((*page >> 12) & 0xFFFFF);
    if (!(cast(bool) frame))
    {
        return;
    }
    else
    {
        clearFrame(frame);
        page = cast(page_t *) (cast(uint) page & 0x00000FFF); // zero the frame address
    }
}

static PageTable *clone_table(PageTable *src, uint *physAddr)
{
    // Make a new page table, which is page aligned.
    PageTable *table = cast(PageTable*)kmalloc_ap(PageTable.sizeof, physAddr);
    // Ensure that the new table is blank.
    memset(table, 0, PageDirectory.sizeof);

    // For every entry in the table...
    int i;
    for (i = 0; i < 1024; i++)
    {
        // If the source entry has a frame associated with it...
        if ((src.pages[i] >> 12) & 0xFFFFF)
        {
            // Get a new frame.
            alloc_frame(&table.pages[i], 0, 0);
            // Clone the flags from source to destination.
            if (src.pages[i] & (1 << 0)) table.pages[i] |= 1 << 0; // present
            if (src.pages[i] & (1 << 1)) table.pages[i] |= 1 << 1; // rw
            if (src.pages[i] & (1 << 2)) table.pages[i] |= 1 << 2; // user
            if (src.pages[i] & (1 << 5)) table.pages[i] |= 1 << 5; // accessed
            if (src.pages[i] & (1 << 6)) table.pages[i] |= 1 << 6; // dirty
            // Physically copy the data across. This function is in process.s.
            // frame
            CopyPagePhysical(((src.pages[i] >> 12) & 0xFFFFF)*0x1000, ((table.pages[i] >> 12) & 0xFFFFF)*0x1000);
        }
    }
    return table;
}

PageDirectory *clone_directory(PageDirectory *src)
{
    uint phys;
	
    //panic();
    // Make a new page directory and obtain its physical address.
    PageDirectory *dir = cast(PageDirectory*)kmalloc_ap(PageDirectory.sizeof, &phys);
    
    // Ensure that it is blank.
    memset(dir, 0, PageDirectory.sizeof);
	
    // Get the offset of tablesPhysical from the start of the page_directory_t structure.
    uint offset = cast(uint)(cast(uint *) dir.tablesPhysical) - cast(uint)dir;

    // Then the physical address of dir.tablesPhysical is:
    dir.physicalAddr = phys + offset;

    // Go through each page table. If the page table is in the kernel directory, do not make a new copy.
    int i;
    for (i = 0; i < 1024; i++) {
        if (!src.tables[i])
            continue;

        if (kernelDirectory.tables[i] == src.tables[i])
        {
            // It's in the kernel, so just use the same pointer.
            dir.tables[i] = src.tables[i];
            dir.tablesPhysical[i] = src.tablesPhysical[i];
        }
        else
        {
            // Copy the table.
            uint phys2;
            dir.tables[i] = clone_table(src.tables[i], &phys2);
            dir.tablesPhysical[i] = phys2 | 0x07;
        }
    }
    return dir;
}
