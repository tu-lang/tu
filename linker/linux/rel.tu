use string

// One relocation: segment name, ELF rela, and symbol name.
mem RelItem {
	string.String* segname
	Elf64_Rela*    rel
	string.String* relname
}

RelItem::init(sname<string.String>, r<Elf64_Rela>, rname<string.String>){
	this.segname = sname
	this.rel = r
	this.relname = rname
}
