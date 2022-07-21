module kernel.serial;
import kernel.common;
import kernel.console;
import kernel.tty;

extern(C++) final class Serial {
	enum Port {
		COM1 = 0x3f8
	}

	extern(C) ushort port;

	int received() {
		ushort port = cast(ushort) (this.port + 5);
		return ReadPortByte(port) & 1;
	}

	byte readUByte() {
		while (this.received() == 0) {}

		return ReadPortByte(this.port);
	}

	int isTransmitEmpty() {
		ushort port = cast(ushort) (this.port + 5);
		return ReadPortByte(port) & 0x20;
	}
 
	void writeUByte(ubyte a) {
		while (this.isTransmitEmpty() == 0) {}

		WritePortByte(this.port, a);
	}

	void initialize(Serial.Port port) {
		ushort tmp;

		this.port = cast(ushort) port;

		tmp = cast(ushort) (this.port + 1);
		WritePortByte(tmp, 0x00u);    // Disable all interrupts
		tmp = cast(ushort) (this.port + 3);
		WritePortByte(tmp, 0x80u);    // Enable DLAB (set baud rate divisor)
		tmp = cast(ushort) (this.port + 0);
		WritePortByte(tmp, 0x03u);    // Set divisor to 3 (lo byte) 38400 baud
		tmp = cast(ushort) (this.port + 1);
		WritePortByte(tmp, 0x00u);    //                  (hi byte)
		tmp = cast(ushort) (this.port + 3);
		WritePortByte(tmp, 0x03u);    // 8 bits, no parity, one stop bit
		tmp = cast(ushort) (this.port + 2);
		WritePortByte(tmp, 0xC7u);    // Enable FIFO, clear them, with 14-byte threshold
		tmp = cast(ushort) (this.port + 4);
		WritePortByte(tmp, 0x0Bu);    // IRQs enabled, RTS/DSR set
		WritePortByte(tmp, 0x1Eu);    // Set in loopback mode, test the serial chip
		tmp = cast(ushort) (this.port + 0);
		WritePortByte(tmp, 0xAEu);    // Test serial chip (send byte 0xAE and check if serial returns same byte)

		// Check if serial is faulty (i.e: not same byte as sent)
		tmp = cast(ushort) (this.port + 0);
		if(ReadPortByte(tmp) != 0xAEu) {
			printk("Faulty serial port.\n");
			panic();
		}

		// If serial is not faulty set it in normal operation mode
		// (not-loopback with IRQs enabled and OUT#1 and OUT#2 bits enabled)
		tmp = cast(ushort) (this.port + 4);
		WritePortByte(tmp, 0x0Fu);
	}
}

void serialPrint(Serial serial, string s) {
	foreach (c; s) {
		serial.writeUByte(cast(ubyte) c);
	}
}

void serialReadLine(Serial serial, out char[] buffer) {
	char c;
	for (int i = 0; i < buffer.length; i++) {
		c = serial.readUByte();
		buffer[i] = c;
		if (c != '\0')
			break;
	}
}
