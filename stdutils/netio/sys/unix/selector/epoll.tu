use std.atomic

EPOLL_CLOEXEC<i64> = 0x80000
LOWEST_FD<i32> = 3
F_DUPFD_CLOEXEC<i32> = 1030

NEXT_ID<atomic.AtomicUsize:> = new atomic.AtomicUsize {
	addr : 0
}

mem Selector {
	u64 id 
	i64 ep
	atomic.AtomicUsize has_waker
}

const Selector::new() Selector {
	flag<i64> = EPOLL_CLOEXEC
	//TODO:
	ep<i32> = os.epoll_create(flag)
	if ep <= 0 {
		runtime.error("epoll create failed")
	}
	return new Selector {
		id: NEXT_ID.fetch_add(1.(i32)),
		ep: ep,
		has_waker: atomic.AtomicUsize{
			addr: 0
		}
	}
}

Selector::try_clone() Selector {
	ret<i32> = os.fcntl(this.ep , F_DUPFD_CLOEXEC,LOWEST_FD)
	if ret <= 0 {
		runtime.errorf(*"Selector::try_clone failed ret:%d\n",ret)
	}
	return new Selector {
		id: this.id,
		ep: ret,
		has_waker: atomic.AtomicUsize {
			addr: this.has_waker.load()
		}
	}
}

Selector::select(events<Events> , timeout<i64> ) i32 {
	events.clear()
	n_events<i32> = os.epoll_wait(
		this.ep,
		this.inner,
		this.capacity(),
		timeout
	)
	if n_events <= 0 {
		runtime.errorf(*"epoll_wait failed ret:%d\n",n_events)
	}
	events.set_len(n_events)
	return n_events
}

Selector::interests_to_epoll(interests<netio.Interest>)  u32 {
	kind<i32> = std.EPOLLET

    if interests.is_readable() {
        kind = std.kind | std.EPOLLIN | std.EPOLLRDHUP
    }

    if interests.is_writable() {
        kind |= std.EPOLLOUT
    }

	return kind
}

Selector::register(fd<i32> , token<u64>, interests<netio.Interest>) i32 {
	event<Event:> = null
	event.events = interests_to_epoll(interests)
	event.data   = token
	//TODO: 
	ret<i32> = os.epoll_ctl(this.ep,std.EPOLL_CTL_ADD,fd,&event)
	if ret <= 0 {
		runtime.errorf(*"epoll_ctl failed ret:%d\n",ret)
	}
	return true
}

Selector::deregister(fd<i32>) i32 {
	//TODO:
	ret<i32> = os.epoll_ctl(this.ep, std.EPOLL_CTL_DEL, fd,null)
	if ret < 0 {
		runtime.dief("epoll_ctl failed:%d",ret)
	}
	return true
}

Selector::register_waker() i32 {
	this.has_waker.swap(true)
}

Selector::id() i64 {
	return this.id
}

Selector::as_raw_fd() i32 {
	return this.ep
}

fn interests_to_epoll(interests<netio.Interest>) u32 {
	kind<i64> = std.EPOLLET
	if interests.is_readable() {
		kind = kind | std.EPOLLIN | std.EPOLLRDHUP
	}
	
	if interests.is_writable() {
		kind |= EPOLLOUT
	}
	return kind
}

mem EpollData {
	u64* ptr
	i32  fd
	u32  f1
	u64  f2
}

mem Event: pack {
	u32 events
	u64 data
} 

mem Events {
	Event* inner
	u64 		size
	u64 		capacity 
}

const Events::with_capacity(capacity<u64>) Events {
	size<i64> = sizeof(Event) * capacity
	return new Events {
		size:     0,
		capacity: capacity,
		inner:    new size
	}
}

Events::capacity() u64 {
	return this.capacity
}

Events::is_empty() i32 {
	return this.size == 0
}

Events::len() i32 {
	return this.size
}

Events::clear() {
	this.size = 0
}

Events::set_len(size<u64>) {
	this.size = size
}

Events::get(i<i32>) Event {
	if i > this.size {
		runtime.dief("events get over index:%d-%d\n",i,this.size)
	}
	return this.inner[i]
}


//Event
fn token(event<Event>) u64 {
	return event.data
}

fn is_readable(event<Event>) i32 {
	ev<i32> = event.events
	if ev & std.EPOLLIN != 0 
		return true
	
	if ev & std.EPOLLPRI != 0 
		return true
	
	return false
}

fn is_writable(event<Event>) i32 {
	ev<i32> = event.events
	if ev & std.EPOLLOUT != 0 
		return true
	return false
}

fn is_error(event<Event>) i32 {
	ev<i32> = event.events
	if ev & std.EPOLLERR != 0
		return true
	return false
}

fn is_read_closed(event<Event>) i32 {
	ev<i32> = event.events
	if ev & std.EPOLLHUP  != 0
		return true
	
	if (ev & std.EPOLLIN != 0 ) && (ev & std.EPOLLRDHUP != 0)
		return true
	
	return false
}

fn is_write_closed(event<Event>) i32 {
	ev<i32> = event.events
	if ev & std.EPOLLHUP != 0
		return true
	
	if ev & std.EPOLLOUT != 0 && ev & std.EPOLLERR != 0 
		return true
	
	if ev == std.EPOLLERR
		return true
	return false
}

fn is_priority(event<Event>) i32 {

	ev<i32> = event.events
	return ev & std.EPOLLPRI != 0
}

fn is_aio(event<Event>) i32 {
	return false
}

fn is_lio(event<Event>) i32 {
	return false
}