// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.orderedlist;
import kernel.heap;
import kernel.common;
import kernel.console;
import kernel.tty;
import kernel.memorystream;

//alias type_t = void *; /* Ordered array entry. */
alias type_t = uint; /* Ordered array entry. */
alias lessthan_predicate_t = byte function(type_t,type_t);

struct OrderedArray {
	type_t[] array;
	uint size;
	uint max_size;
	lessthan_predicate_t less_than;
}

byte standard_lessthan_predicate(type_t a, type_t b)
{
	return (a < b)? 1 : 0;
}

@trusted uint[] new_ordered_array(uint max_size)
{
	uint *r;
	int len = max_size * type_t.sizeof;
	r = cast(uint *) kmalloc(len);
	memset(r, 0, max_size * type_t.sizeof);
	return r[0..len];
}

/* Allocate and initialize ordered array. */
@safe OrderedArray create_ordered_array
	(uint max_size,
	 lessthan_predicate_t less_than)
{
	OrderedArray oa;

	oa.array = new_ordered_array(max_size);
	
	oa.size = 0;
	oa.max_size = max_size;
	oa.less_than = less_than;
	
	return oa;
}

/* Initialize ordered array. */
OrderedArray place_ordered_array
	(void *addr,
	 uint max_size,
	 lessthan_predicate_t less_than)
{
	OrderedArray oa;
	
	oa.array = (cast(type_t *) addr)[0..max_size];
	for (int i = 0; i < max_size; i++)
		oa.array[i] = 0;

	oa.size = 0;
	oa.max_size = max_size;
	oa.less_than = less_than;
	
	return oa;
}

void destroy_ordered_array(ref OrderedArray oa)
{
	kfree(cast(void *) oa.array);
}

extern(C)
void insert_ordered_array(type_t item, ref OrderedArray oa)
{
	if (oa.less_than == null)
		panic();
	uint iterator = 0;
	/* Find the last slot less than "item". */
	while (iterator < oa.size &&
		oa.less_than(oa.array[iterator], item))
		iterator++;
	
	/* If item is the greatest in the array,
	 * append it to the array and increment the size. */
	if (iterator == oa.size) {
        oa.array[oa.size] = item; // !!! oa.size++ has precedence in D.
        oa.size++;
	} else {
		type_t tmp = oa.array[iterator]; /* Save the least slot less than "item". */
		oa.array[iterator] = item; /* Overwrite it. */
		while (iterator < oa.size) {
			/* make the iterator point to the first slot greater than "item". (zero-indexed) */
			iterator++;
			type_t tmp2 = oa.array[iterator]; /* Make it equal to the last item. */
			oa.array[iterator] = tmp;
			tmp = tmp2; /* This is the last item now. */
		}
		oa.size++;
	}
}

type_t lookup_ordered_array(uint i, ref OrderedArray oa)
{
	if (!(i < oa.size)) {
		printk("ERROR: lookup_ordered_array: i >= oa.size\n");
		panic();
	}
	return oa.array[i];
}

void remove_ordered_array(uint i, ref OrderedArray oa)
{
	for ( ; i < oa.size; i++) {
		oa.array[i] = oa.array[i + 1];
	}
	oa.size--;
}
