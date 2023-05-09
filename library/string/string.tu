
use runtime
use std
Null<i64> = 0

mem String {
	u8* inner
}
func S(s<i8*>){
	return new String {
		inner : newstring(s)
	}
}
func emptyS(){
	return new String {
		inner : newlen(*"",Null)
	}
}
func string(){
	return new String {
		inner : newlen(*"" , Null)
	}
}

String::str(){
	return this.inner
}
String::hash64(){
	return this.inner.(Str).hash64()
}

String::dup() {
	return new String {
		inner : this.inner.(Str).dup()
	}
}
String::dyn() {
	return runtime.newobject(
		runtime.STRING,
		this.inner,
		this.inner.(Str).hash64()
	)
}
String::sub(start<i64> , len<i64>){
	return new String {
		inner : newlen(this.inner + start , len)
	}
}
String::tonumber(){
	dl<i64> = 0
	if this.inner[0] == '0' && this.inner[1] == 'x'
        dl = std.strtoul(this.inner,0.(i8),16.(i8))
	else if this.inner[0] == '-'
    	dl = std.strtol(this.inner,0.(i8),10.(i8))
    else
		dl = std.strtoul(this.inner,0.(i8),10.(i8))
	return dl
}
String::cat(t<String>) {
	newp<i8*> = this.inner.(Str).catlen(
		t.inner,t.inner.(Str).len()
	)
	this.inner = newp
}
String::catstr(t<i8*>){
	this.inner = this.inner.(Str).cat(
		t
	)
}

String::tolower() {
	this.inner.(Str).tolower()
}

String::toupper() {
	this.inner.(Str).toupper()
}
String::cmp(s2<String>) {
	return this.inner.(Str).cmp(s2.inner)
}
String::cmpstr(s2<i8*>){
	if ( ret<i8> = std.strcmp(this.inner,s2)) != runtime.Zero {
		return 1.(i8)
	}
	return 0.(i8)
}
String::empty(){
	if this.cmpstr("".(i8)) == Null 
		return True
	return False
}
String::putc(c<i8>){
	this.inner = this.inner.(Str).putc(c)
}
String::len(){
	return this.inner.(Str).len()
}