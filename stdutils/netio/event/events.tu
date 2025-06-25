use netio.sys.unix.selector


mem Events {
	selector.Events* inner // arr
}

const Events::with_capacity(capacity<u64>) Events {
	return new Events {
		inner: selector.Events::with_capacity(capacity)
	}
}


Events::capacity() u64 {
    return this.inner.capacity()
}

Events::is_empty() i32 {
	return this.inner.is_empty()
}

Events::clear(){
	this.inner.clear()
}

Events::iter() Iter {
	return new Iter {
		inner: this,
		pos: 0
	}
}

Events::sys() selector.Events {
	return this.inner
}

mem Iter {
	Events* inner
	u64  	pos
}

Iter::next() selector.Event {
	ret<u64*> = this.inner.inner.get(
		this.pos
	)
	//TODO: next to end
	this.pos += 1
	return ret
}

Iter::size_hint() i64, i64 {
	size = this.inner.inner.len()
	return size,size
}

Iter::count() i64 {
	return this.inner.inner.len()
}