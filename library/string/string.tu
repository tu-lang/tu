
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

// C string pointer for libc (getaddrinfo etc.); mother Path/OsStr::as_bytes/as_ptr.
fn cstr(s<String>) i8* {
	return s.str()
}

// Cross-package path bridge: string_to_bits copies the cstr into an owned
// GC buffer. path_bits must not hold a raw String* (u64 slots are not traced).
fn cstr_from_bits(bits<u64>) i8* {
	p<i8*> = bits
	return p
}

fn string_to_bits(s<String>) u64 {
	src<i8*> = s.inner
	if src == null {
		empty<i8*> = new 1
		*empty = 0
		return empty.(u64)
	}
	n_u<u64> = std.strlen(src)
	n_i<i32> = n_u.(i32)
	alloc_n<i32> = n_i + 1
	dst<i8*> = new alloc_n
	std.memcpy(dst, src, n_u)
	end<i8*> = dst + n_i
	*end = 0
	return dst.(u64)
}

fn string_from_bits(bits<u64>) String {
	p<i8*> = bits
	return S(p)
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
		return i, null, null
	}
	secondS<i32> = pos + sep.len()
	secondE<i32> = this.len() - secondS
	return true, this.sub(0,pos), this.sub(secondS,secondE)
}

// Cross-pkg bridges for string.String member calls (sys/net LookupHost port parse).
fn rsplit_once(s<String>, sep<String>) i32, String, String {
	err<i32>, a<String>, b<String> = s.rSplitOnce(sep)
	return err, a, b
}

fn tonumber_i64(s<String>) i64 {
	return s.tonumber()
}