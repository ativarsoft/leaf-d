module kernel.serial;
import kernel.common;
import kernel.console;

enum PORT = 0x3f8;          // COM1

int SerialReceived() {
	return ReadPortByte(PORT + 5) & 1;
}

char ReadSerial() {
	while (SerialReceived() == 0) {}

	return ReadPortByte(PORT);
}

int IsTransmitEmpty() {
	return ReadPortByte(PORT + 5) & 0x20;
}
 
void WriteSerial(char a) {
	while (IsTransmitEmpty() == 0) {}

	WritePortByte(PORT, a);
}

void InitializeSerial()
{
	WritePortByte(PORT + 1, 0x00);    // Disable all interrupts
	WritePortByte(PORT + 3, 0x80);    // Enable DLAB (set baud rate divisor)
	WritePortByte(PORT + 0, 0x03);    // Set divisor to 3 (lo byte) 38400 baud
	WritePortByte(PORT + 1, 0x00);    //                  (hi byte)
	WritePortByte(PORT + 3, 0x03);    // 8 bits, no parity, one stop bit
	WritePortByte(PORT + 2, 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
	WritePortByte(PORT + 4, 0x0B);    // IRQs enabled, RTS/DSR set
	WritePortByte(PORT + 4, 0x1E);    // Set in loopback mode, test the serial chip
	WritePortByte(PORT + 0, 0xAE);    // Test serial chip (send byte 0xAE and check if serial returns same byte)

	// Check if serial is faulty (i.e: not same byte as sent)
	if(ReadPortByte(PORT + 0) != 0xAE) {
		printk("Faulty serial port.\n");
		panic();
	}

	// If serial is not faulty set it in normal operation mode
	// (not-loopback with IRQs enabled and OUT#1 and OUT#2 bits enabled)
	WritePortByte(PORT + 4, 0x0F);
}
