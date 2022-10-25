
Null<i64> = 0

mem String {
	u8* inner
}

func string(){
	return new String {
		inner : newlen(*"" , Null)
	}
}

String::str(){
	return this.inner
}

String::dup() {
	return new String {
		inner : this.inner.(Str).dup()
	}
}
String::cat(t<String>) {
	newp<i8*> = this.inner.(Str).catlen(
		t.inner,t.inner.(Str).len()
	)
	this.inner = newp
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
String::putc(c<i8>){
	this.inner = this.inner.(Str).putc(c)
}
String::len(){
	return this.inner.(Str).len()
}