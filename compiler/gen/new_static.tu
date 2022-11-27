use ast 
use compile
use internal
use parser
use parser.package
use std
use utils
use fmt

StructInitExpr::arrinit(ctx , field , arr){
	if field.arrsize != std.len(arr.lit)  {
		fmt.println(field.arrsize,std.len(arr.lit))
		this.check(false,"arr size is not same")
	}
	elmentsize = field.size
	ltok = field.type
	if field.pointer {
		elmentsize = 8
		ltok = ast.U64
	}
	compile.Push()
	for i : arr.lit {
		if type(i) == type(IntExpr) {
			compile.writeln("	mov $%s,%%rax",i.lit)
		}else if type(i) == type(StringExpr) {
			compile.writeln("	lea %s(%%rip),%%rax",i.name)
		}else{
			ret = i.compile(ctx)
			if type(ret) == type(StructMemberExpr) {
				m = ret
				v = m.getMember() 
				compile.LoadMember(v)
			}
		}
		compile.writeln(" mov (%%rsp) , %%rdi")
		compile.Cast(i.getType(ctx),ltok) 
		compile.StoreNoPop(elmentsize)
		compile.writeln("	add $%d , (%%rsp)",elmentsize)
	}
	compile.Pop("%rax")
	return this
}
StructInitExpr::compile(ctx){
	compile.Push()
	s = package.getStruct(this.pkgname,this.name)
	if(s == null) this.panic("struct not exist when new struct")
	for key,value : this.fields {
		field = s.getMember(key)
		if field == null  this.panic("struct member field not exist :"+ key)
		rtok = ast.U64
		isunsigned = false
		if type(value) == type(IntExpr) {
			rtok = value.getType(ctx)
			compile.writeln("	mov $%s,%%rax",ie.lit)
		}else if type(value) == type(StringExpr) {
			rtok = value.getType(ctx)
			isunsigned = true
			compile.writeln("	lea %s(%%rip),%%rax",value.name)
		}else if type(value) == type(StructInitExpr) {
			ie = value
			if field.structname != ie.name this.panic("type sould be same")
			compile.writeln("	mov (%%rsp) , %%rax")
			compile.writeln("	add $%d , %%rax",field.offset)
			ie.compile(ctx)
			continue 
		}else if type(value) == type(ArrayExpr) {
			ie = value
			if !field.isarr this.panic("mem field must be static arr")
			compile.writeln("	mov (%%rsp) , %%rax")
			compile.writeln("	add $%d , %%rax",field.offset)
			this.arrinit(ctx,field,ie)
			continue
		}else{
			rtok = value.getType(ctx)
			ret = value.compile(ctx)
			if ret != null && type(ret) == type(StructMemberExpr) {
				m = ret
				m = ret
				v = m.getMember() 
				compile.LoadMember(v)
			}
		}
		compile.writeln(" mov (%%rsp) , %%rdi")
		compile.writeln(" add $%d , %%rdi",field.offset)
		ltok = field.type
		if  field.pointer ltok = ast.U64
		compile.Cast(rtok,ltok) 
		size = field.size
		if field.pointer size = 8
		compile.StoreNoPop(size)
	}
	compile.Pop("%rax")
	return this
}
NewStructExpr::compile(ctx){
	if this.init == null this.panic("new struct is null")
	s = package.getStruct(this.init.pkgname,this.init.name)
	if s == null this.panic("struct not exist when new struct")
	internal.gc_malloc(s.size)
	this.init.compile(ctx)
	return this
}