use netio
use netio.sys.unix.selector

EFD_CLOEXEC<i64> = 0x80000
EFD_NONBLOCK<i64> = 0x800

mem Waker {
	fd: i32,
}

const Waker::new(selector<selector.Selector>, token<u64>) Waker {
	//TODO:
	fd<i32> = os.eventfd(0, EFD_CLOEXEC, EFD_NONBLOCK)	
	if fd < 0 {
		runtime.dief("eventfd error:%d",fd)
	}
	if selector.register(fd, token, netio.READABLE) != true {
		runtime.dief("selector.register failed")
	}
	return new Waker {
		fd: fd
	}
}

Waker::wake() i32 {
	buf<i64> = 1
	ret<i32> = std.write(this.fd, &buf , 8)
	if ret != 8 {
		if ret == std.EAGAIN {
			this.reset()
			this.wake()
		}else {
			runtime.dief("wake failed:%d",ret)
		}
	}
	return true
}

Waker::reset() i32 {
	buf<i64> = 0
	ret<i32> = std.read(this.fd,&buf, 8)
	if ret != 8 {
		if ret == std.EAGAIN {
			return true
		}
		runtime.dief("wake reset failed:%d",ret)
	}
	return true
}

