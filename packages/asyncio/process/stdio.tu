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
    err<i32>, _ = sys.cvt(sys_close(fd))
    return err
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
    fn poll_write(ctx<u64>, buf<io.Buf>) i32, u64 {
        err<i32>, n<u64> = sys.cvt(sys_write(this.fd, buf.ptr(), buf.len()))
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
        base<io.Buf> = buf.inner.buf
        _, tail<io.Buf> = base.split_at(buf.filled)
        err<i32>, n<u64> = sys.cvt(sys_read(this.fd, tail.ptr(), tail.len()))
        if err != io.Ok return runtime.PollError
        if n > 0 buf.advance(n)
        return runtime.PollReady
    }
}

// AsyncRead over the stderr pipe (mirror of ChildStdout).
impl aio.AsyncRead for ChildStderr {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        base<io.Buf> = buf.inner.buf
        _, tail<io.Buf> = base.split_at(buf.filled)
        err<i32>, n<u64> = sys.cvt(sys_read(this.fd, tail.ptr(), tail.len()))
        if err != io.Ok return runtime.PollError
        if n > 0 buf.advance(n)
        return runtime.PollReady
    }
}

// Read every byte from `fd` into a freshly grown io.Buf (blocking, to EOF).
// Returns (io.Ok, buf) with buf.len() == total bytes, or (err, null).
fn read_all_fd(fd<i32>) i32, io.Buf {
    buf<io.Buf> = io.NewBuf(4096)
    total<u64> = 0
    loop {
        if total >= buf.len() {
            grown<io.Buf> = io.NewBuf((buf.len() * 2).(i32))
            std.memcpy(grown.ptr(), buf.ptr(), total)
            buf = grown
        }
        err<i32>, n<u64> = sys.cvt(sys_read(fd, buf.ptr() + total, buf.len() - total))
        if err != io.Ok return err, null
        if n == 0 break
        total += n
    }
    return io.Ok, new io.Buf { inner: buf.ptr(), len: total }
}
