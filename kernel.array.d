module kernel.array;
import kernel.heap;

extern(C++) final class Array(T) {
	extern(C) T *data;
	extern(C) size_t length;
	extern(C) size_t capacity;

	T get(size_t idx) {
		T[] arr = this.data[0..this.length];
		return arr[idx];
	}

	int append(T a) {
		assert(this.length <= this.capacity);
		T[] arr = this.data[0..this.capacity];
		int l = this.length;
		arr[l] = a;
		this.length++;
		return l;
	}

	void init(int n) {
		this.data = cast(T*) kmalloc(T.sizeof * n);
		this.length = 0;
		this.capacity = n;
	}
};
