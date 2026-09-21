use linker.linux
use string

// Symbol link: undefined recv ↔ defined prov for one symbol name.
mem SymLink {
	string.String* name
	linux.File*    recv
	linux.File*    prov
}

SymLink::init(){
	this.name = null
	this.recv = null
	this.prov = null
}
