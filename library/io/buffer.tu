
use runtime
use std
Null<i64> = 0

mem Buf {
	u8* inner
}
func NewBuf(){
	return new Buf {
		inner : string.newlen(*"",Null)
	}
}

Buf::data(){
	return this.inner
}
Buf::dup() {
	return new Buf {
		inner : this.inner.(Str).dup()
	}
}
Buf::sub(start<i64> , len<i64>){
	return new Buf {
		inner : newlen(this.inner + start , len)
	}
}
Buf::cat(t<String>) {
	newp<i8*> = this.inner.(Str).catlen(
		t.inner,t.inner.(Str).len()
	)
	this.inner = newp
}
Buf::catstr(t<i8*>){
	this.inner = this.inner.(Str).cat(
		t
	)
}

Buf::tolower() {
	this.inner.(Str).tolower()
}

Buf::toupper() {
	this.inner.(Str).toupper()
}
Buf::cmp(s2<String>) {
	return this.inner.(Str).cmp(s2.inner)
}
Buf::cmpstr(s2<i8*>){
	if ( ret<i8> = std.strcmp(this.inner,s2)) != runtime.Zero {
		return 1.(i8)
	}
	return 0.(i8)
}
Buf::empty(){
	if this.cmpstr("".(i8)) == Null 
		return True
	return False
}
Buf::putc(c<i8>){
	this.inner = this.inner.(Str).putc(c)
}

Buf::len(){
	return this.inner.(Str).len()
}

Buf::ptr() i8* {
	return this.inner
}
