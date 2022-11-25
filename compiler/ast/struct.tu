class Struct {
	pkg  = ""
	name = ""
	size = 0
	align = 0
	member = [] # [Member]

	iscomputed = false
	ispacked = false
	parser = null

}
class Member
{
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
	structpkg
	structname
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