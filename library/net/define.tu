Err<i32> = -1
Ok<i32>  = 1
None<i32> = -1
Has<i32>   = 1

fn tou16(b1<u8>, b2<u8> ) u16 {
	f1<u16> = b 
	f1 <<= 8

	f2<u16> = b2
	return f1 | f2
}

fn copy_tail_to_head_u8(head<u8*>, head_size<i32>, tail<u8*>, tail_size<i32>) {
    if tail_size > head_size {
        tail_size = head_size
    }
    std.memcpy(head + (head_size - tail_size), tail, tail_size)
}

fn copy_tail_to_head_u16(head<u16*>, head_len<i32>, tail<u16*>, tail_size<i32> ) {
    if tail_size > head_len {
        tail_size = head_len;
    }

    std.memcpy(
        head + (head_len - tail_size), 
        tail,                      
        tail_size * sizeof(uint16_t)    
    )
}
