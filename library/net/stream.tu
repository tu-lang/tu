use io
use sys


mem UnixStream { 
    sys.Socket* inner
}

UnixStream::try_clone() i32,UnixStream {
    ok<i32>, fd<sys.Socket*> = this.inner.duplicate()
    if ok {
        return new UnixStream{
            inner: fd
        }
    } 
    return Err
}

UnixStream::take_error() i32, i32 , i32 {
    ok<i32>,has<i32>,err<i32> = this.inner.take_error()
    return ok,has,err
}

UnixStream::shutdown(how<i32>) i32 {    
    return this.inner.shutdown(how)
}
UnixStream::fromrawfd(fd<sys.RawFd>) UnixStream {
    return new UnixStream{
        inner: new sys.Socket{
            fd: sys.FileDesc::from_raw_fd(fd)
        }
    }
}


impl io.Read for UnixStream {
    fn read(buf<io.Buffer>) i32,u64 {
        err<i32>,size<u64> = this.inner.read(buf)
        return err,size
    }
}

impl io.Write for UnixStream {
    fn write(buf<io.Buffer>) i32,u64 {
        err<i32>, size<u64> = this.inner.write(buf)
        return err,size
    }
}

impl sys.AsRawFd for UnixStream {
    fn as_raw_fd()  sys.RawFd {
        return this.inner.as_raw()
    }
}