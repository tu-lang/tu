use netio
use netio.sys.unix.selector

mem Event {
    selector.Event* inner
}

Event::token() u64 {
    return selector.token(this.inner)
}

Event::is_readable() i32 {
    return selector.is_readable(this.inner)
}

Event::is_writable() i32 {
    return selector.is_writable(this.inner)
}

Event::is_error() i32 {
    return selector.is_error(this.inner)
}

Event::is_read_closed() i32 {
    return selector.is_read_closed(this.inner)
}

Event::is_write_closed() i32 {
    return selector.is_write_closed(this.inner)
}

Event::is_priority() i32 {
    return selector.is_priority(this.inner)
}

Event::is_aio() i32 {
    return selector.is_aio(this.inner)
}

Event::is_lio() i32 {
    return selector.is_lio(this.inner)
}
