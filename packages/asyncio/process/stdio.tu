// Child stdio handles (tokio::process::ChildStdin / ChildStdout / ChildStderr).
//
// Design note (task 17.1): the spec models these as `class X { PollEvented* io }`
// wrapping a pipe registered with the IO driver. Per library-static-only these
// are `mem` types; and since the runtime IO driver / blocking pool are not yet
// wired (same state that keeps net/fs on their V1 paths), the pipe fd is driven
// synchronously here: AsyncRead/AsyncWrite perform one blocking read/write and
// resolve immediately. The reactor-backed non-blocking path (pipe2 O_NONBLOCK +
// PollEvented) lands once the runtime root is wired.

use runtime
use io
use std
use sys
use asyncio.io as aio

// Write half connected to the child's stdin. Holds the parent's write end.
mem ChildStdin {
    i32 fd
}

// Read half connected to the child's stdout. Holds the parent's read end.
mem ChildStdout {
    i32 fd
}

// Read half connected to the child's stderr. Holds the parent's read end.
mem ChildStderr {
    i32 fd
}

// Close a stdio fd once (idempotent-ish; fd set to -1 afterwards).
fn close_fd(fd<i32>) i32 {
    if fd < 0 return io.Ok
    r<i32> = sys.close(fd)
    if r < 0 {
        err<i32> = sys.cvt(r)
        return err
    }
    return io.Ok
}

ChildStdin::close() i32 {
    e<i32> = close_fd(this.fd)
    this.fd = -1
    return e
}
ChildStdout::close() i32 {
    e<i32> = close_fd(this.fd)
    this.fd = -1
    return e
}
ChildStderr::close() i32 {
    e<i32> = close_fd(this.fd)
    this.fd = -1
    return e
}

// AsyncWrite over the stdin pipe: one blocking write, resolve immediately.
// poll_flush is a no-op; poll_shutdown closes the write end (EOF for the child).
impl aio.AsyncWrite for ChildStdin {
    fn poll_write(ctx<u64>, buf_bits<u64>) i32, u64 {
        buf<io.Buf> = io.buf_from_bits(buf_bits)
        p<u8*> = io.buf_ptr(buf)
        err<i32>, n<u64> = sys.cvt(sys.write(this.fd, p, io.buf_len(buf)))
        if err != io.Ok return runtime.PollError, 0
        return runtime.PollReady, n
    }
    fn poll_flush(ctx<u64>) i32 {
        return runtime.PollReady
    }
    fn poll_shutdown(ctx<u64>) i32 {
        this.close()
        return runtime.PollReady
    }
}

// AsyncRead over the stdout pipe: fill the unfilled tail with one blocking read.
impl aio.AsyncRead for ChildStdout {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        rem<u64> = buf.remaining()
        if rem == 0 return runtime.PollReady
        err<i32>, n<u64> = sys.cvt(sys.read(this.fd, buf.unfilled_ptr(), rem))
        if err != io.Ok return runtime.PollError
        if n > 0 buf.advance(n)
        return runtime.PollReady
    }
}

// AsyncRead over the stderr pipe (mirror of ChildStdout).
impl aio.AsyncRead for ChildStderr {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        rem<u64> = buf.remaining()
        if rem == 0 return runtime.PollReady
        err<i32>, n<u64> = sys.cvt(sys.read(this.fd, buf.unfilled_ptr(), rem))
        if err != io.Ok return runtime.PollError
        if n > 0 buf.advance(n)
        return runtime.PollReady
    }
}

// Read every byte from `fd` into a freshly grown io.Buf (blocking, to EOF).
// Returns (io.Ok, buf) with exact byte length, or (err, null).
fn read_all_fd(fd<i32>) i32, io.Buf {
    cap_i<i32> = 4096
    buf<io.Buf> = io.NewBuf(cap_i)
    total<u64> = 0
    loop {
        blen<u64> = io.buf_len(buf)
        if total >= blen {
            // Grow capacity (mother drains stdout/stderr into a Vec).
            next_u<u64> = blen + blen
            next_i<i32> = next_u.(i32)
            grown<io.Buf> = io.NewBuf(next_i)
            std.memcpy(io.buf_ptr(grown), io.buf_ptr(buf), total)
            buf = grown
            blen = io.buf_len(buf)
        }
        rem<u64> = blen - total
        base<u8*> = io.buf_ptr(buf)
        dst<u8*> = base + total
        err<i32>, n<u64> = sys.cvt(sys.read(fd, dst, rem))
        if err != io.Ok return err, null
        if n == 0 break
        total += n
    }
    return io.Ok, io.buf_with_len(buf, total)
}
