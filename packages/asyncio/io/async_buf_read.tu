// Async buffered-read interface. Layered on AsyncRead — implementors
// expose poll_fill_buf for callers that want to peek without copying,
// then consume(amt) when the bytes are taken.
//
// Filled-slice is returned as (state, data_bits, len). Prefer bare `use io`
// for library types; call sites rebuild io.Buf via helpers. The design
// AsyncBufRead returns &[u8].

use runtime

api AsyncBufRead {
    fn poll_fill_buf(ctx<u64>) (i32, u64, u64)
    fn consume(amt<u64>)
}
