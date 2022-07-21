module kernel.pci;
import kernel.common;
import kernel.console;
import kernel.tty;

private enum {
	configAddress = 0xCF8,
	configData = 0xCFC
}

extern(C++) final class PCI {
	struct Device {
		ushort deviceID;
		ushort vendorID;

		ushort status;
		ushort command;

		ubyte classCode;
		ubyte subclassCode;
		ubyte progIF;
		ubyte revisionID;

		ubyte bist;
		ubyte headerType;
		ubyte latencyTimer;
		ubyte cacheLineSize;

		uint[6] bar;

		uint cardbusCISPointer;

		ushort subsystemID;
		ushort subsystemVendorID;

		uint expansionROMBaseAddress;

		ushort reserved0;
		ushort capabilitiesPointer;

		uint reserved1;

		ubyte maxLatency;
		ubyte minGrant;
		ubyte interruptPIN;
		ubyte interruptLine;
	}

	void getDevice(ubyte bus, ubyte slot) {
		ushort word;
		PCI.Device device;

		word = this.readData(bus, slot, 0, 0);
		device.deviceID = word;
		word = this.readData(bus, slot, 0, 1);
		device.vendorID = word;

		word = this.readData(bus, slot, 0, 2);
		device.status = word;
		word = this.readData(bus, slot, 0, 3);
		device.command = word;

		word = this.readData(bus, slot, 0, 4);
		device.classCode = word & 0xFF;
		device.subclassCode = word & 0xFF;
		word = this.readData(bus, slot, 0, 5);
		device.bar[0] = word;
		device.bar[0] = word;

		word = this.readData(bus, slot, 0, 6);
		device.bar[0] = word;
		device.bar[0] = word;
		word = this.readData(bus, slot, 0, 7);
		device.bar[0] = word;
		device.bar[0] = word;

		word = this.readData(bus, slot, 0, 8);
		device.bar[0] = word;
		word = this.readData(bus, slot, 0, 9);
		device.bar[0] ^= word << 16;

		word = this.readData(bus, slot, 0, 10);
		device.bar[1] = word;
		word = this.readData(bus, slot, 0, 11);
		device.bar[1] ^= word << 16;

		word = this.readData(bus, slot, 0, 12);
		device.bar[2] = word;
		word = this.readData(bus, slot, 0, 13);
		device.bar[2] ^= word << 16;

		word = this.readData(bus, slot, 0, 14);
		device.bar[3] = word;
		word = this.readData(bus, slot, 0, 15);
		device.bar[3] ^= word << 16;

		word = this.readData(bus, slot, 0, 16);
		device.bar[4] = word;
		word = this.readData(bus, slot, 0, 17);
		device.bar[4] ^= word << 16;

		word = this.readData(bus, slot, 0, 18);
		device.bar[5] = word;
		word = this.readData(bus, slot, 0, 19);
		device.bar[5] ^= word << 16;

		word = this.readData(bus, slot, 0, 20);
		device.cardbusCISPointer = word;
		word = this.readData(bus, slot, 0, 21);
		device.cardbusCISPointer ^= word << 16;

		word = this.readData(bus, slot, 0, 22);
		device.subsystemID = word;
		word = this.readData(bus, slot, 0, 23);
		device.subsystemVendorID = word;

		word = this.readData(bus, slot, 0, 24);
		device.expansionROMBaseAddress = word;
		word = this.readData(bus, slot, 0, 25);
		device.expansionROMBaseAddress ^= word << 16;

		word = this.readData(bus, slot, 0, 26);
		device.reserved0 = word;
		word = this.readData(bus, slot, 0, 27);
		device.capabilitiesPointer = word;

		word = this.readData(bus, slot, 0, 28);
		device.reserved1 = word;
		word = this.readData(bus, slot, 0, 29);
		device.reserved1 ^= word << 16;

		word = this.readData(bus, slot, 0, 30);
		device.maxLatency = word & 0xFF;
		device.minGrant = word & 0xFF;
		word = this.readData(bus, slot, 0, 31);
		device.interruptPIN = word & 0xFF;
		device.interruptLine = word & 0xFF;
	}

	void scanForDevices() {
		ushort tmp;

		for (ubyte bus = 0; bus < 255; bus++) {
			for (ubyte slot = 0; slot < 32; slot++) {
				tmp = readData(bus, slot, 0, 0);
				if (tmp == ushort.max)
					continue;

				this.getDevice(bus, slot);

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
