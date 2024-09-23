use compiler.ast 
use compiler.compile
use compiler.internal
use compiler.parser
use compiler.parser.package
use std
use compiler.utils
use fmt

StructInitExpr::arrinit(ctx , field , arr){
    utils.debugf("gen.StructInitExpr::arrinit()")
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
			real = GP().pkg.get_string(i)
			compile.writeln("	lea %s(%%rip),%%rax",real.name)
		}else if type(i) == type(FloatExpr){
			compile.writeln("	mov $%d , %%rax",i.lit)
			compile.writeln("	movq %%rax , %%xmm0")
		}else{
			i.compile(ctx,true)
		}
		compile.writeln(" mov (%%rsp) , %%rdi")

		itype = i.getType(ctx)
		compile.Cast(itype,ltok)
		if ast.isfloattk(itype)
			compile.StorefNoPop(itype)
		else 
			compile.StoreNoPop(elmentsize)

		compile.writeln("	add $%d , (%%rsp)",elmentsize)
	}
	compile.Pop("%rax")
	return this
}

StructInitExpr::compile_field(ctx,load,s,value,field){
	rtok = ast.U64
	isunsigned = false

	if type(value) == type(AsmExpr) {
		compile.writeln(value.label)
		return rtok
	}

	if s.asyncfn != null {
		utils.debugf("asyncfn struct compile: filed:%s",s.asyncfn.name)
		if exprIsMtype(value,ctx) {
			rtok = value.getType(ctx)
		}
		value.compile(ctx,true)
		return rtok
	}

	if type(value) == type(BoolExpr) {
		rtok = value.getType(ctx)
		ie   = value
		compile.writeln("	mov $%d,%%rax",ie.lit)
	}else if type(value) == type(NullExpr) {
		rtok = value.getType(ctx)
		ie   = value
		compile.writeln("	mov $%d,%%rax",0)
	}else if type(value) == type(CharExpr) {
		rtok = value.getType(ctx)
		ie   = value
		compile.writeln("	mov $%s,%%rax",ie.lit)
	}else if type(value) == type(IntExpr) {
		rtok = value.getType(ctx)
		ie   = value
		compile.writeln("	mov $%s,%%rax",ie.lit)
	}else if type(value) == type(FloatExpr) {
		rtok = value.getType(ctx)
		compile.writeln("	mov $%d,%%rax",value.lit)
		compile.writeln("	movq %%rax , %%xmm0")
	}else if type(value) == type(StringExpr) {
		real = GP().pkg.get_string(value)
		rtok = value.getType(ctx)
		isunsigned = true
		compile.writeln("	lea %s(%%rip),%%rax",real.name)
	}else if type(value) == type(StructInitExpr) {
		ie = value
		if field.structname != ie.name this.panic("type sould be same")
		compile.writeln("	mov (%%rsp) , %%rax")
		compile.writeln("	add $%d , %%rax",field.offset)
		ie.compile(ctx,true)
		return rtok
	}else if type(value) == type(ArrayExpr) {
		ie = value
		if !field.isarr this.panic("mem field must be static arr")
		compile.writeln("	mov (%%rsp) , %%rax")
		compile.writeln("	add $%d , %%rax",field.offset)
		this.arrinit(ctx,field,ie)
		return rtok
	}else{
		rtok = value.getType(ctx)
		value.compile(ctx,true)
	}
	return rtok
}

StructInitExpr::compile(ctx,load){
    utils.debugf("gen.StructInitExpr::compile()")
	compile.Push()
	fullpkg = GP().getImport(this.pkgname)
	s = package.getStruct(fullpkg,this.name)
	if(s == null) this.check(false,"struct not exist when new struct")

	if s.isasync {
		fc = s.getFunc("poll")
		if fc == null {
			this.check(false,"poll not exist")
		}
		value = "	lea "
		value += s.futurepollname()
		value += "(%%rip) , %%rax"
		this.fields["poll.f"] = new AsmExpr(value,this.line,this.column)
	}
	for key,value : this.fields {
		field = s.getMember(key)
		if field == null  this.check(false,"struct member field not exist :"+ key)

		rtok = this.compile_field(ctx,load,s,value,field)
		if s.asyncfn == null {
			if type(value) == type(StructInitExpr) continue
			if type(value) == type(ArrayExpr) continue
		}

		compile.writeln(" mov (%%rsp) , %%rdi")
		compile.writeln(" add $%d , %%rdi",field.offset)
		ltok = field.type
		if  field.pointer ltok = ast.U64
		compile.Cast(rtok,ltok) 
		size = field.size
		if field.pointer size = 8

		if ast.isfloattk(field.type)
			compile.StorefNoPop(field.type)
		else
			compile.StoreNoPop(size)
	}
	compile.Pop("%rax")
	return this
}
NewStructExpr::compile(ctx,load){
	if this.init == null this.check(false,"new struct is null")
	fullpackage = GP().getImport(this.init.pkgname)
	s = package.getStruct(fullpackage,this.init.name)
	if s == null this.check(false,"struct not exist when new struct")
	internal.gc_malloc(s.size)
	this.init.compile(ctx,true)
	return this
}