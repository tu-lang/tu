use compiler.parser.package
use compiler.utils

class Struct {
	isapi  = false
	pkg    = ""
	name   = ""
	size   = 0
	align  = 0
	member = [] //[Member]

	iscomputed = false
	ispacked = false
	isasync  = false
	asyncobj = false
	asyncfn  = null

	member   = []
	apis     = {}
	
	parser = null
	funcs  = {} // funcs
}

class Member
{
	parent = null
	name
	type
	size
	isunsigned
	pointer

	idx
	align
	offset
	
	bitfield
	bitoffset
	bitwidth
	
	arrsize
	isarr
	arrvar

	
	isstruct
	structpkg = ""
	structname = ""
	structref
	
	line
	column
	file
}


Struct::getMember(name)
{
	for(i : this.member){
		if i.name == name
		return i
	}
	return null
}

Member::clone(){
	m = new Member()
	m.parent = this.parent
	m.name = this.name
	m.type = this.type
	m.size = this.size
	m.isunsigned = this.isunsigned
	m.pointer = this.pointer
	m.idx = this.idx
	m.align = this.align
	m.offset = this.offset
	m.bitfield = this.bitfield
	m.bitoffset = this.bitoffset
	m.bitwidth = this.bitwidth
	m.arrsize = this.arrsize
	m.isarr = this.isarr
	m.arrvar = this.arrvar
	m.isstruct = this.isstruct
	m.structpkg = this.structpkg
	m.structname = this.structname
	m.structref = this.structref
	m.line = this.line
	m.column = this.column
	m.file = this.file
	return m
}

Struct::getPoll(){
	if !this.isasync {
		this.parser.check(false,"not async struct,can't get poll")
	}
	fc = this.asyncfn
	if fc != null {
		if fc.fntype != ast.AsyncFunc {
			this.parser.check(false,"asyncfn not async type")
		}
		return fc
	}
	return this.getFunc("poll")
}

Struct::getFunc(name){
	if this.funcs[name] != null
		return this.funcs[name]
	return null
}

Struct::futurepollname(){
	p = this.parser
	name = "virtfh_" + p.getpkgname()
	name += "_"
	name += this.name
	name += "poll"
	return name
}
