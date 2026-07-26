// Integration test (task 15.16): TCP echo round-trip over asyncio.net.tcp.
// Uses TcpStream::poll_read / poll_write via local leaf futures (static
// member dispatch). Avoids asyncio.io.util's `u64.(AsyncRead).poll_*` path,
// which currently codegen's a lea of the missing api-method symbol instead
// of vtable dyn-dispatch.
//
// Reads use the direct io.Buf bits bridge (stream_poll_read_buf).

use fmt
use os
use io
use string
use std
use net
use time
use runtime
use asyncio.runtime as rt
use asyncio.net as anet
use asyncio.net.tcp as tcp

// Pin GC roots across await (u64 bits are not traced as pointers).
PIN_OWN1<io.Buf> = null
PIN_OWN2<io.Buf> = null

fn str_buf(s<string.String>) io.Buf {
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    p<i8*> = b.ptr()
    std.memcpy(p, s.str(), slen.(u64))
    return b
}

// Print buffer length only (per-byte dump at package level hits ptr-arith traps).
fn dump_len(tag_id<i32>, n<u64>) {
    fmt.println("dump_tag")
    fmt.println(int(tag_id))
    fmt.println("  nbytes")
    fmt.println(int(n))
}

// Print n bytes from u8* in the async body (indexing works here).
fn dump_bytes_u8(tag_id<i32>, p<u8*>, n<u64>) {
    fmt.println("dump_bytes_tag")
    fmt.println(int(tag_id))
    fmt.println("  nbytes")
    fmt.println(int(n))
    i<u64> = 0
    while i < n {
        b<i32> = 0
        b = p[i]
        fmt.println("  byte_idx")
        fmt.println(int(i))
        fmt.println("  byte_val")
        fmt.println(int(b & 255))
        i += 1
    }
}

fn step(n<i32>) {
    fmt.println("--- step")
    fmt.println(int(n))
}

// WriteAll leaf over a concrete TcpStream (mother: tokio::io::WriteAll).
// remain_bits: async mem cannot hold io.Buf fields (assignment zeros len).
mem EchoWriteAll: async {
    tcp.TcpStream* stream
    u64            remain_bits
    i32            done_code
    i32            tag
}

const EchoWriteAll::new(s<tcp.TcpStream>, buf<io.Buf>, tag<i32>) EchoWriteAll {
    f<EchoWriteAll> = new EchoWriteAll
    f.stream = s
    f.remain_bits = io.buf_to_bits(buf)
    f.done_code = 0
    f.tag = tag
    return f
}

EchoWriteAll::poll(ctx) {
    ready<i32> = runtime.PollReady
    pend<i32> = runtime.PollPending
    ok_code<i32> = 1
    wz<i32> = 16908312
    if this.done_code != 0 {
        return ready, this.done_code
    }
    rem<io.Buf> = io.buf_from_bits(this.remain_bits)
    while io.buf_len(rem) > 0 {
        bits<u64> = io.buf_to_bits(rem)
        st<i32>, n<u64> = tcp.stream_poll_write(this.stream, ctx, bits)
        if st == pend {
            fmt.println("write_pending")
            fmt.println(int(this.tag))
            fmt.println(int(io.buf_len(rem)))
            this.remain_bits = bits
            return pend
        }
        if st == runtime.PollError || n == 0 {
            fmt.println("write_error")
            fmt.println(int(this.tag))
            fmt.println(int(st))
            fmt.println(int(n))
            this.done_code = wz
            return ready, wz
        }
        fmt.println("write_chunk")
        fmt.println(int(this.tag))
        fmt.println(int(n))
        fmt.println(int(io.buf_len(rem)))
        head<io.Buf>, tail<io.Buf> = rem.split_at(n)
        rem = tail
        this.remain_bits = io.buf_to_bits(rem)
    }
    fmt.println("write_done")
    fmt.println(int(this.tag))
    return ready, ok_code.(i64)
}

// Read leaf over a concrete TcpStream into an io.Buf (bits).
mem EchoRead: async {
    tcp.TcpStream* stream
    u64            buf_bits
    i32            tag
}

const EchoRead::new(s<tcp.TcpStream>, buf<io.Buf>, tag<i32>) EchoRead {
    f<EchoRead> = new EchoRead
    f.stream = s
    f.buf_bits = io.buf_to_bits(buf)
    f.tag = tag
    return f
}

EchoRead::poll(ctx) {
    ok_code<i32> = 1
    fail_code<i32> = 16908329
    st<i32>, n<u64> = tcp.stream_poll_read_buf(this.stream, ctx, this.buf_bits)
    if st == runtime.PollPending {
        fmt.println("read_pending")
        fmt.println(int(this.tag))
        return runtime.PollPending
    }
    if st == runtime.PollError {
        fmt.println("read_error")
        fmt.println(int(this.tag))
        return runtime.PollReady, fail_code.(i64), 0.(u64)
    }
    fmt.println("read_ready")
    fmt.println(int(this.tag))
    fmt.println(int(n))
    return runtime.PollReady, ok_code.(i64), n
}

async tcp_echo_body() {
    step(1)
    fmt.println("parse addr 127.0.0.1:34567")
    addr_s<string.String> = string.S(*"127.0.0.1:34567")
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, addr_bits<u64> = anet.parse_socket_addr(addr_s.str(), slen)
    fmt.println("parse_err")
    fmt.println(int(perr))
    if perr != io.Ok return perr
    addr<net.SocketAddr> = addr_bits.(net.SocketAddr)

    step(2)
    fmt.println("bind listener")
    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(addr)
    fmt.println("bind_err")
    fmt.println(int(berr))
    if berr != io.Ok return berr

    step(3)
    fmt.println("client connect BEFORE accept (fills listen backlog)")
    fmt.println("connect_await_start")
    cerr<i32>, client<tcp.TcpStream> = tcp.TcpStream::connect(addr).await
    fmt.println("connect_done_err")
    fmt.println(int(cerr))
    if cerr != io.Ok return cerr

    step(4)
    fmt.println("server accept (pending connection already in backlog)")
    fmt.println("accept_await_start")
    aerr2<i32>, server<tcp.TcpStream> = listener.accept().await
    fmt.println("accept_done_err")
    fmt.println(int(aerr2))
    if aerr2 != io.Ok return aerr2

    step(5)
    fmt.println("client write payload ping")
    msg<string.String> = string.S(*"ping")
    mlen<i32> = std.strlen(msg.str())
    fmt.println("payload_len")
    fmt.println(int(mlen))
    wbuf<io.Buf> = str_buf(msg)
    dump_len(1, mlen.(u64))
    wp<u8*> = null
    wp = wbuf.ptr()
    dump_bytes_u8(1, wp, mlen.(u64))
    // write_tag=1 client→server
    werr<i32> = EchoWriteAll::new(client, wbuf, 1).await
    fmt.println("client_write_err")
    fmt.println(int(werr))
    if werr != io.Ok return werr

    step(6)
    fmt.println("server read expect ping")
    own1<io.Buf> = io.NewBuf(16)
    PIN_OWN1 = own1
    // read_tag=2 server recv
    rerr<i32>, rn<u64> = EchoRead::new(server, own1, 2).await
    fmt.println("server_read_err")
    fmt.println(int(rerr))
    fmt.println("server_read_n")
    fmt.println(int(rn))
    if rerr != io.Ok return rerr
    dump_len(2, rn)
    rp1<u8*> = null
    rp1 = own1.ptr()
    dump_bytes_u8(2, rp1, rn)
    if rn != mlen.(u64) {
        fmt.println("server_read_len_mismatch")
        return io.OtherParse
    }

    step(7)
    fmt.println("server echo write same bytes back")
    echo<io.Buf> = io.NewBuf(rn.(i32))
    ep<i8*> = echo.ptr()
    sp1<i8*> = own1.ptr()
    std.memcpy(ep, sp1, rn)
    dump_len(3, rn)
    ep8<u8*> = null
    ep8 = ep
    dump_bytes_u8(3, ep8, rn)
    // write_tag=3 server→client
    werr2<i32> = EchoWriteAll::new(server, echo, 3).await
    fmt.println("server_echo_write_err")
    fmt.println(int(werr2))
    if werr2 != io.Ok return werr2

    step(8)
    fmt.println("client read echo expect ping")
    own2<io.Buf> = io.NewBuf(16)
    PIN_OWN2 = own2
    // read_tag=4 client recv echo
    rerr2<i32>, n2<u64> = EchoRead::new(client, own2, 4).await
    fmt.println("client_read_err")
    fmt.println(int(rerr2))
    fmt.println("client_read_n")
    fmt.println(int(n2))
    if rerr2 != io.Ok return rerr2
    dump_len(4, n2)
    rp2<u8*> = null
    rp2 = own2.ptr()
    dump_bytes_u8(4, rp2, n2)
    if n2 != mlen.(u64) {
        fmt.println("client_read_len_mismatch")
        return io.OtherParse
    }

    step(9)
    fmt.println("byte compare")
    src<u8*> = msg.str()
    got_i8<i8*> = own2.ptr()
    got<u8*> = null
    got = got_i8
    i<u64> = 0
    while i < n2 {
        if got[i] != src[i] {
            fmt.println("byte_mismatch_at")
            fmt.println(int(i))
            g<i32> = 0
            g = got[i]
            s0<i32> = 0
            s0 = src[i]
            fmt.println(int(g & 255))
            fmt.println(int(s0 & 255))
            return io.OtherParse
        }
        i += 1
    }
    fmt.println("bytes_match_ok")
    // Hold with sockets still open so ss/tcpdump can observe ESTABLISHED.
    // Prefer asyncio Sleep, but enable_time()+TCP connect currently segfaults;
    // use blocking time.sleep so the pause is usable for inspection.
    step(10)
    fmt.println("hold 10s (blocking time.sleep) — inspect TCP now")
    fmt.println("hint: ss -tn sport = :34567 or dport = :34567")
    time.sleep(10)
    fmt.println("hold_done")
    PIN_OWN1 = null
    PIN_OWN2 = null
    step(11)
    fmt.println("body done io.Ok")
    return io.Ok
}

fn int_tcp_echo(){
    fmt.println("int_tcp_echo test")
    fmt.println("build runtime (current_thread + enable_io)")
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_io()
    body<runtime.Future> = tcp_echo_body()
    if body == null {
        os.die("tcp_echo_body returned null future")
    }
    fut_bits<u64> = 0
    fut_bits = body
    fmt.println("block_on start")
    rerr<i32>, result<i64> = rt.builder_block_on(b, fut_bits, 0)
    fmt.println("block_on returned")
    fmt.println(int(rerr))
    if rerr != 0 {
        fmt.println("block_on failed")
        os.exit(1)
    }
    ri<i32> = 0
    ri = result
    fmt.println("body_result")
    fmt.println(int(ri))
    if ri != io.Ok {
        fmt.println("body failed")
        os.exit(1)
    }
    fmt.println("int_tcp_echo passed")
}

fn main(){
    int_tcp_echo()
}
