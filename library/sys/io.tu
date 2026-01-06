mem IoSlice {
    u8* iov_base
    u64 iov_len
}

const IoSlice::new(buf<u8*>, buf_len<u64>) IoSlice {
    return new IoSlice {
        iov_base: buf, 
        iov_len: buf_len,
    }
}

IoSlice::as_slice() u8* {
    return this.iov_base
}

mem IoSliceMut {
    u8* iov_base
    u64 iov_len
}

IoSliceMut::as_slice() u8* {
    return this.iov_base
}

IoSliceMut::as_mut_slice() u8* {
    return this.iov_base
}