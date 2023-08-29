// Copyright (C) 2023 Mateus de Lima Oliveira

// Memory management and safety note:
// The compiler zeroes the memory of the struct when it is allocated.
// If the kernel programmer tries to free a vector with uninitialized memory,
// the functions that free vectors will take advantage of that memory
// initialization feature of the compiler.

// TODO: multitasking and locks.

module kernel.vector;
import kernel.heap;

template Vector(T) {
    alias Refcount = size_t *;

    private struct Vector {
        //int lock;

        // Reference counting is important for the cases where the struct is
        // copied for preventing pointer aliasing.
        size_t *refcount;

        T *data;
        size_t length;
    }

    @trusted
    private void initilize_reference_counting(out Refcount refcount)
    {
        refcount = cast(Refcount) kmalloc(Refcount.sizeof);
        *refcount = 1;
    }

    @trusted
    private size_t get_reference_counting(Refcount refcount)
    {
        return *refcount;
    }

    @trusted
    private size_t decrement_reference_count(Refcount refcount)
    in(refcount != null)
    {
        size_t rc = *refcount;
        assert(rc > 0);
        rc--;
        *refcount = rc;
        return rc;
    }

    @safe
    public void init(out Vector v)
    {
        initialize_reference_counting(v.refcount);
        v.data = null;
        v.length = 0;
    }

    @trusted
    public void free(ref Vector v)
    {
        size_t refcount = decrement_reference_count(v.refcount);
        if (refcount == 0) {
            v.length = 0;
            if (v.data != null) {
                kfree(v.data);
            }
        }
    }

    @trusted
    public T get(ref Vector v, size_t idx)
    {
        assert(idx < v.length);
        return v.data[idx];
    }

    @trusted
    void set(ref Vector v, T item, size_t idx)
    {
        assert(idx < v.length);
        v.data[idx] = item;
    }
}

