use std
use io
use sys

// TCP stream wrapper around sys.TcpStream (tustd::net::TcpStream).
// hub_bits: raw bits of sys.TcpStream* — avoid `sys.TcpStream*` mem fields
// (cross-pkg typed pointers load garbage under current codegen).
mem TcpStream {
    u64 hub_bits
}

// TCP listener wrapper around sys.TcpListener (tustd::net::TcpListener).
mem TcpListener {
    u64 hub_bits
}

const TcpListener::fromrawfd(fd<i32>) TcpListener {
    out<TcpListener> = new TcpListener
    out.hub_bits = sys.tcp_listener_from_fd(fd)
    return out
}

TcpListener::as_raw_fd() i32 {
    return sys.tcp_listener_as_raw_fd_bits(this.hub_bits)
}

impl sys.AsRawFd for TcpListener {
    fn as_raw_fd() i32 {
        return sys.tcp_listener_as_raw_fd_bits(this.hub_bits)
    }
}

const TcpStream::fromrawfd(fd<i32>) TcpStream {
    out<TcpStream> = new TcpStream
    out.hub_bits = sys.tcp_stream_from_fd(fd)
    return out
}

TcpStream::shutdown(how<i32>) i32 {
    return sys.tcp_stream_shutdown_bits(this.hub_bits, how)
}

TcpStream::take_error() i32,i32,i32 {
    ok<i32>, has<i32>, ret<i32> = sys.tcp_stream_take_error_bits(this.hub_bits)
    return ok, has, ret
}

TcpStream::asinner_bits() u64 {
    return this.hub_bits
}

TcpStream::as_raw_fd() i32 {
    return sys.tcp_stream_as_raw_fd_bits(this.hub_bits)
}

impl sys.AsRawFd for TcpStream {
    fn as_raw_fd() i32 {
        return sys.tcp_stream_as_raw_fd_bits(this.hub_bits)
    }
}

impl io.Read for TcpStream {
    fn read(buf<io.Buf>) i32,u64 {
        err<i32>, size<u64> = sys.tcp_stream_read_bits(this.hub_bits, buf)
        return err, size
    }
}

impl io.Write for TcpStream {
    fn write(buf<io.Buf>) i32,u64 {
        err<i32>, size<u64> = sys.tcp_stream_write_bits(this.hub_bits, buf)
        return err, size
    }
    fn flush() i32 {
        return io.Ok
    }
}
