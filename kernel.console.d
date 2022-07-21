// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.console;
import kernel.common;
import kernel.tty;

struct cons {
	int ypos; //Starting points of the cursor
	int xpos;
	uint COLUMNS; //Screensize
	uint LINES;
}

static __gshared ubyte *vidmem = cast(ubyte*)0xFFFF_8000_000B_8000;

static __gshared cons default_console = cons(0, 0, 80, 25);

@trusted @live ubyte[] get_vidmem_slice(ref cons c) {
	return vidmem[0..c.LINES * c.COLUMNS * 2];
}

@safe void cls(ref cons c)
{
	ubyte[] vidmem = get_vidmem_slice(c);
	// Loops through the screen and clears it
	for (int i = 0; i < c.COLUMNS * c.LINES * 2; i+=2) {
		vidmem[i] = ' ';
		vidmem[i+1] = 0x07;
	}
	c.xpos = 0;
	c.ypos = 0;
	MoveCursor(c);
}

/* Convert the integer D to a string and save the string in BUF. If
   BASE is equal to 'd', interpret that D is decimal, and if BASE is
   equal to 'x', interpret that D is hexadecimal. */
@system static void itoa (char *buf, int base, int d)
{
	char *p = buf;
	char * p1, p2;
	uint ud = d;
	int divisor = 10;

	/* If %d is specified and D is minus, put `-' in the head. */
	if (base == 'd' && d < 0) {
		*p++ = '-';
		buf++;
		ud = -d;
	} else if (base == 'x') {
		divisor = 16;
	}

	/* Divide UD by DIVISOR until UD == 0. */
	do {
		uint remainder = ud % divisor;

		*p++ = cast(char) ((remainder < 10) ? remainder + '0' : remainder + 'a' - 10);
	} while (ud /= divisor);

	/* Terminate BUF. */
	*p = 0;

	/* Reverse BUF. */
	p1 = buf;
	p2 = p - 1;
	while (p1 < p2) {
		char tmp = *p1;
		*p1 = *p2;
		*p2 = tmp;
		p1++;
		p2--;
	}
}

@system static void scroll(ref cons c)
{
	// Get a space character with the default colour attributes.
	ubyte attributeByte = (0 /*black*/ << 4) | (15 /*white*/ & 0x0F);
	ushort blank = 0x20 /* space */ | (attributeByte << 8);

	// Row 25 is the end, this means we need to scroll up
	if(c.ypos >= 25) {
		// Move the current text chunk that makes up the screen
		// back in the buffer by a line
		int i;
		for (i = 0*0; i < 24*80*2; i++){
			vidmem[i] = vidmem[i+80*2];
		}

		// The last line should now be blank. Do this by writing
		// 80 spaces to it.
		for (i = 24*80*2; i < 25*80*2; i++) {
			vidmem[i] = 0;
		}
		// The cursor should now be on the last line.
		c.ypos = 24;
	}
}

@safe static void MoveCursor(const cons c)
{
	//ushort cursorLocation = cast(ushort) (c.ypos * c.COLUMNS + c.xpos);
	ushort cursorLocation = cast(ushort) (c.xpos + c.ypos * c.COLUMNS);
	WritePortByte(0x3D4, 14);                  // Tell the VGA board we are setting the high cursor byte.
	WritePortByte(0x3D5, cast(ubyte) (cursorLocation >> 8)); // Send the high cursor byte.
	WritePortByte(0x3D4, 15);                  // Tell the VGA board we are setting the low cursor byte.
	WritePortByte(0x3D5, cast(ubyte) cursorLocation);      // Send the low cursor byte.
}

@trusted void _consoleWrite(ref cons c, string s)
{
	ubyte[] vidmem = get_vidmem_slice(c);
	foreach (a; s) {
		if (a == '\n') {
			c.xpos = 0;
			c.ypos += 1;
			continue;
		}
		if (a == '\0') {
			MoveCursor(c);
			return;
		}
		scroll(c);
		//volatileStore(vidmem + (c.xpos + c.ypos * c.COLUMNS) * 2, a & 0xFF); //Prints the letter D
		//volatileStore(vidmem + (c.xpos + c.ypos * c.COLUMNS) * 2 + 1, 0x07); //Sets the colour for D to be light grey (0x07)
		vidmem[(c.xpos + c.ypos * c.COLUMNS) * 2] = a & 0xFF; //Prints the letter D
		vidmem[(c.xpos + c.ypos * c.COLUMNS) * 2 + 1] = 0x07; //Sets the colour for D to be light grey (0x07)
		c.xpos++;
		if (c.xpos >= c.COLUMNS) {
			c.ypos += 1;
			c.xpos = 0;
		}
	}
	MoveCursor(c);
}

void consoleTTYWrite(ref TTYDeviceData data, string s)
{
	_consoleWrite(data.console, s);
}

@trusted static void consoleWrite(string s) {
	_consoleWrite(default_console, s);
}

@trusted void PrintIntHex(int x)
{
	char[20] buf;
	itoa(cast(char *) buf, 'x', x);
	printk(cast(string) buf);
}

@safe void PrintNewLine()
{
	printk("\n");
}

static __gshared TTYDeviceOperations consoleDevice = {
	write: &consoleTTYWrite
};
