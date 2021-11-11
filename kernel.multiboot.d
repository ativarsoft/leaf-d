// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.multiboot;

static __gshared const uint MULTIBOOT_FLAG_MEM     = 0x001;
static __gshared const uint MULTIBOOT_FLAG_DEVICE  = 0x002;
static __gshared const uint MULTIBOOT_FLAG_CMDLINE = 0x004;
static __gshared const uint MULTIBOOT_FLAG_MODS    = 0x008;
static __gshared const uint MULTIBOOT_FLAG_AOUT    = 0x010;
static __gshared const uint MULTIBOOT_FLAG_ELF     = 0x020;
static __gshared const uint MULTIBOOT_FLAG_MMAP    = 0x040;
static __gshared const uint MULTIBOOT_FLAG_CONFIG  = 0x080;
static __gshared const uint MULTIBOOT_FLAG_LOADER  = 0x100;
static __gshared const uint MULTIBOOT_FLAG_APM     = 0x200;
static __gshared const uint MULTIBOOT_FLAG_VBE     = 0x400;

struct Multiboot
{
	align (1):
    uint flags;
    uint mem_lower;
    uint mem_upper;
    uint boot_device;
    uint cmdline;
    uint mods_count;
    uint mods_addr;
    uint num;
    uint size;
    uint addr;
    uint shndx;
    uint mmap_length;
    uint mmap_addr;
    uint drives_length;
    uint drives_addr;
    uint config_table;
    uint boot_loader_name;
    uint apm_table;
    uint vbe_control_info;
    uint vbe_mode_info;
    uint vbe_mode;
    uint vbe_interface_seg;
    uint vbe_interface_off;
    uint vbe_interface_len;
};
