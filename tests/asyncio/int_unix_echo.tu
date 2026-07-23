// Integration test (task 15.17): Unix-domain stream echo round-trip over
// asyncio.net.unix. Uses local leaf futures (static member dispatch) like
// int_tcp_echo; avoids asyncio.io.util dyn-dispatch on u64 slots.

use fmt
use os
use io
use string
use std
use runtime
use asyncio.runtime as rt
use asyncio.net.unix as unix
use asyncio.io as aio

fn make_read_buf(cap<i32>) aio.ReadBuf {
    b<io.Buf> = io.NewBuf(cap)
    p<i8*> = b.ptr()
    bits<u64> = 0
    bits = p
    // Keep Buf alive via bits in ReadBuf is insufficient for GC; unix path
    // still needs the same io.Buf echo refactor as int_tcp_echo.
    return aio.read_buf_from_bits_cap(bits, cap.(u64))
}

fn str_buf(s<string.String>) io.Buf {
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    std.memcpy(b.ptr(), s.str(), slen.(u64))
    return b
}

mem EchoWriteAll: async {
    unix.UnixStream* backing
    io.Buf         remain
    i32            done_code
}

const EchoWriteAll::new(s<unix.UnixStream>, buf<io.Buf>) EchoWriteAll {
    f<EchoWriteAll> = new EchoWriteAll
    f.backing = s
    f.remain = buf
    f.done_code = 0
    return f
}

EchoWriteAll::poll(ctx) {
    ready<i32> = runtime.PollReady
    pend<i32> = runtime.PollPending
    if this.done_code != 0 {
        return ready, this.done_code
    }
    rem<io.Buf> = this.remain
    while rem.len() > 0 {
        bits<u64> = io.buf_to_bits(rem)
        st<i32>, n<u64> = this.backing.poll_write(ctx, bits)
        if st == pend {
            this.remain = rem
            return pend
        }
        if st == runtime.PollError || n == 0 {
            this.done_code = st
            return ready, st
        }
        rem = io.buf_slice(rem, n)
    }
    this.done_code = io.Ok
    return ready, io.Ok
}

mem EchoRead: async {
    unix.UnixStream* backing
    aio.ReadBuf      buf
    u64              start
}

const EchoRead::new(s<unix.UnixStream>, rb<aio.ReadBuf>) EchoRead {
    f<EchoRead> = new EchoRead
    f.backing = s
    f.buf = rb
    f.start = rb.filled_len()
    return f
}

EchoRead::poll(ctx) {
    ready<i32> = runtime.PollReady
    pend<i32> = runtime.PollPending
    st<i32> = this.backing.poll_read(ctx, this.buf)
    if st == pend {
        return pend
    }
    if st != io.Ok {
        return ready, st, 0.(i64)
    }
    delta<u64> = this.buf.filled_len() - this.start
    return ready, io.Ok, delta
}

async unix_echo_body() {
    path<string.String> = string.S(*"/tmp/asyncio_int_unix_echo.sock")

    berr<i32>, listener<unix.UnixListener> = unix.UnixListener::bind(path)
    if berr != io.Ok return berr

    cerr<i32>, client<unix.UnixStream> = unix.UnixStream::connect(path).await
    if cerr != io.Ok return cerr

    aerr2<i32>, server<unix.UnixStream> = listener.accept().await
    if aerr2 != io.Ok return aerr2

    msg<string.String> = string.S(*"ping")
    mlen<i32> = std.strlen(msg.str())

    wfut<EchoWriteAll> = EchoWriteAll::new(client, str_buf(msg))
    werr<i32> = wfut.await
    if werr != io.Ok return werr

    rbuf<aio.ReadBuf> = make_read_buf(16)
    rfut<EchoRead> = EchoRead::new(server, rbuf)
    rerr<i32>, n<u64> = rfut.await
    if rerr != io.Ok return rerr
    if n != mlen.(u64) return io.OtherParse

    echo<io.Buf> = io.NewBuf(int(n))
    std.memcpy(echo.ptr(), rbuf.data_ptr(), n)
    wfut2<EchoWriteAll> = EchoWriteAll::new(server, echo)
    werr2<i32> = wfut2.await
    if werr2 != io.Ok return werr2

    rbuf2<aio.ReadBuf> = make_read_buf(16)
    rfut2<EchoRead> = EchoRead::new(client, rbuf2)
    rerr2<i32>, n2<u64> = rfut2.await
    if rerr2 != io.Ok return rerr2
    if n2 != mlen.(u64) return io.OtherParse

    src<u8*> = msg.str()
    got<u8*> = rbuf2.data_ptr()
    i<u64> = 0
    while i < n2 {
        if got[i] != src[i] return io.OtherParse
        i += 1
    }
    return io.Ok
}

fn int_unix_echo(){
    fmt.println("int_unix_echo test")

    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    body<runtime.Future> = unix_echo_body()
    fut_bits<u64> = 0
    fut_bits = body
    rerr<i32>, result<i64> = rt.builder_block_on(b, fut_bits, 0)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    if result.(i32) != io.Ok os.dief("unix echo body failed: %d", result.(i32))
    fmt.println("int_unix_echo passed")
}

fn main(){
    int_unix_echo()
}
