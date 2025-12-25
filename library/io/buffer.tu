
use runtime
use std
Null<i64> = 0

mem Buffer {
	u8* inner
}
func NewBuffer(){
	return new Buffer {
		inner : string.newlen(*"",Null)
	}
}

Buffer::data(){
	return this.inner
}
Buffer::dup() {
	return new Buffer {
		inner : this.inner.(Str).dup()
	}
}
Buffer::sub(start<i64> , len<i64>){
	return new Buffer {
		inner : newlen(this.inner + start , len)
	}
}
Buffer::cat(t<String>) {
	newp<i8*> = this.inner.(Str).catlen(
		t.inner,t.inner.(Str).len()
	)
	this.inner = newp
}
Buffer::catstr(t<i8*>){
	this.inner = this.inner.(Str).cat(
		t
	)
}

Buffer::tolower() {
	this.inner.(Str).tolower()
}

Buffer::toupper() {
	this.inner.(Str).toupper()
}
Buffer::cmp(s2<String>) {
	return this.inner.(Str).cmp(s2.inner)
}
Buffer::cmpstr(s2<i8*>){
	if ( ret<i8> = std.strcmp(this.inner,s2)) != runtime.Zero {
		return 1.(i8)
	}
	return 0.(i8)
}
Buffer::empty(){
	if this.cmpstr("".(i8)) == Null 
		return True
	return False
}
Buffer::putc(c<i8>){
	this.inner = this.inner.(Str).putc(c)
}

Buffer::len(){
	return this.inner.(Str).len()
}

Buffer::ptr() i8* {
	return this.inner
}
