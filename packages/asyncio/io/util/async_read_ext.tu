// AsyncRead extension helpers. `Read` is a leaf future for one
// poll_read call. Package-level async must only return the leaf (no await).
//
// Factories take typed `aio.AsyncRead` (vtable dispatch). Leaf futures
// store the implementor and ReadBuf as u64 bits so async frames stay
// GC-safe and avoid `pkg.Type*` mem-body / value-nest traps.
// Poll paths use u64 bits + tyassert dispatch (InitApiVptr only on assign/new).

use runtime
use io as iobuf
use asyncio.io as aio

mem Read: async {
    u64 r
    u64 buf_bits
    u64 start
    i32 started
}

const Read::new(r<u64>, buf<aio.ReadBuf>) Read {
    f<Read> = new Read
    f.r = r
    f.buf_bits = aio.read_buf_to_bits(buf)
    f.start = 0
    f.started = 0
    return f
}

Read::poll(ctx) {
    rb<aio.ReadBuf> = aio.read_buf_from_bits(this.buf_bits)
    if this.started == 0 {
        this.start = rb.filled_len()
        this.started = 1
    }
    err<i32> = this.r.(aio.AsyncRead).poll_read(ctx, rb)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        other_err<i32> = 16908329
        zero<u64> = 0.(u64)
        return runtime.PollReady, other_err, zero
    }
    delta<u64> = rb.filled_len() - this.start
    ok_code<i32> = 1
    return runtime.PollReady, ok_code, delta
}

fn reader_bits(r<aio.AsyncRead>) u64 {
    bits<u64> = 0
    bits = r
    return bits
}

fn read(r<aio.AsyncRead>, buf<aio.ReadBuf>) Read {
    return Read::new(reader_bits(r), buf)
}

// Build ReadBuf over an io.Buf (this package may use io; asyncio.io must not).
fn read_buf_over(buf<iobuf.Buf>) aio.ReadBuf {
    return aio.read_buf_from_i8(iobuf.buf_ptr(buf), iobuf.buf_len(buf))
}
