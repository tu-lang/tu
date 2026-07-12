use netio
use io
use sys as libsys

mem EventfdWaker {
	libsys.FileDesc* fd
}

const EventfdWaker::new(selector<Selector>, t<netio.Token>) i32, EventfdWaker {
	fd<i32> = sys_eventfd(0, 0x80000 | 0x800)
	if fd == -1
		return libsys.last_error(), null

	file<libsys.FileDesc> = new libsys.FileDesc { fd: fd }
	err<i32> = selector.register(fd, t, netio.readable_interest())
	if err != Ok {
		file.close()
		return err, null
	}

	return Ok, new EventfdWaker { fd: file }
}

EventfdWaker::wake() i32 {
	buf<io.Buf> = new io.Buf {
		inner: new 8,
		len: 8
	}
	*buf.inner = 1
	err<i32>, junk<u64> = this.fd.write(buf)
	if err == io.WouldBlock {
		err = this.reset()
		if err != Ok
			return err
		return this.wake()
	}
	return err
}

EventfdWaker::reset() i32 {
	buf<io.Buf> = new io.Buf {
		inner: new 8,
		len: 8
	}
	err<i32>, junk<u64> = this.fd.read(buf)
	if err == io.WouldBlock
		return Ok
	return err
}
