// Copyright (C) 2022 Mateus de Lima Oliveira

// Support for the TTY device class.
// Examples of TTY drivers:
//   * Terminals
//

module kernel.tty;
import kernel.console;
import kernel.serial;
import kernel.array;

struct TTY {
	int device;
}

static __gshared TTY[8] tty;

enum TTY_MAJOR = 1;
enum TTY_MINOR = 0;

union TTYDeviceData {
	cons console;
	Serial serial;
}

struct TTYDeviceOperations {
	void function(ref TTYDeviceData data, string data) write;
}

struct TTYDevice {
	TTYDeviceData data;
	TTYDeviceOperations ops;
};

static __gshared Array!TTYDevice tty_devices;

@trusted TTY getTTY(int id)
{
	return tty[id];
}

@trusted void setTTY(int id, TTY data)
{
	tty[id] = data;
}

@trusted TTYDevice getTTYDevice(int id)
{
	return tty_devices.get(id);
}

@trusted void printk(string s)
{
	TTY tty0;
	tty0 = getTTY(0);
	TTYDevice device;
	device = getTTYDevice(tty0.device);
	device.ops.write(device.data, s);
}

int registerTTYDevice(TTYDevice device)
{
	return tty_devices.append(device);
}

void initTTY()
{
	tty_devices.init(16);

	TTYDevice dev;
	dev.data.console = default_console;
	dev.ops = consoleDevice;
	int id = registerTTYDevice(dev);

	TTY tty0;
	tty0 = getTTY(0);
	tty0.device = id;
	setTTY(0, tty0);
}
