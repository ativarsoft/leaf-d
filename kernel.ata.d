module kernel.ata;

extern(C++) final class ATA {
	enum PRIMARY   = 0x00;
	enum SECONDARY = 0x01;

	enum READ  = 0x00;
	enum WRITE = 0x01;
}

