
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
String::dyn(cache<i8>) {
	if !cache 
	return new runtime.StringValue {
		base : runtime.Value {
			type : runtime.String,
			data : this.inner
		}
	}
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

String::cmp(s2<String>) i32 {
	return this.inner.(Str).cmp(s2.inner)
}

String::cmpstr(s2<i8*>) i32 {
	if ( ret<i8> = std.strcmp(this.inner,s2)) != runtime.Zero {
		return 1.(i8)
	}
	return 0.(i8)
}
String::empty() i32 {
	if this.cmpstr("".(i8)) == Null 
		return True
	return False
}

String::putc(c<i8>){
	this.inner = this.inner.(Str).putc(c)
}

String::len() i32 {
	return this.inner.(Str).len()
}

String::lastStringIndex(sep<String>) i32,i32 {
	if sep.empty() {
		return this.len()
	}
	if sep.len() > this.len() {
		return -1
	}
	s1<i8*> = this.str()
	s2<i8*> = sep.str()
	for i<i32> = this.len() - sep.len(); i >= 0; i -= 1 {
		mat<i32> = true
		for j<i32> = 0; j < sep.len(); j += 1 {
			if s1[i+j] != s2[j] {
				mat = false
				break
			}
		}
		if mat {
			return true,i
		}
	}
	return -1
}

String::rSplitOnce(sep<string.String>) i32,String,String {
	i<i32>,pos<i32> = this.lastStringIndex(sep)
	if i < 0 {
		return i
	}
	secondS<i32> = pos + sep.len()
	secondE<i32> = this.len() - secondS
	return true, this.sub(0,pos), this.sub(secondS,secondE)
}