module kernel.pci;
import kernel.common;
import kernel.console;

private enum {
	configAddress = 0xCF8,
	configData = 0xCFC
}

extern(C++) final class PCI {
	void scanForDevices() {
		ushort tmp;

		for (ubyte bus = 0; bus < 255; bus++) {
			for (ubyte slot = 0; slot < 32; slot++) {
				tmp = readData(bus, slot, 0, 0);
				if (tmp == ushort.max)
					continue;

				char[20] buf;
				printk("Found PCI device.\n");
				printk("    Bus: ");
				PrintIntHex(bus);
				PrintNewLine();
				printk("    Slot: ");
				PrintIntHex(slot);
				PrintNewLine();
			}
		}
	}

	ushort readData(ubyte bus, ubyte slot, ubyte func, ubyte offset) {
		uint address = cast(uint)((bus << 16) | (slot << 11) | (func << 8) | (offset & 0xfc) | (cast(uint)0x80000000));

		WritePortLong(configAddress, address);
		return cast(ushort)(ReadPortLong(configData) >> ((offset & 2) * 8));
	}
}
