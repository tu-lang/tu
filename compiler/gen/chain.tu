use compiler.ast
use compiler.parser
use compiler.parser.package
use compiler.compile
use std
use compiler.utils

class ChainExpr   : ast.Ast {
    first
    last
    fields = [] # array[Ast] 
	func init(line,column){
		super.init(line,column)
	}
}
ChainExpr::toString() {
    str = "ChainExpr("
    str += "left=" + this.first.toString()
    for(i : this.fields){
        str += "." + i.toString()
    }
    str += ",right=" + this.last.toString()
    str += ")"
    return str
}
ChainExpr::ismem(ctx) {
	if(type(this.first) == type(StructMemberExpr)) return true
	if(type(this.first) == type(IndexExpr)) {
		return exprIsMtype(this.first,ctx)
	}
	if type(this.first) == type(VarExpr) {
		varexpr = this.first
		realVar = varexpr.getVar(ctx,this)
		if realVar && !realVar.is_local && realVar.structtype {
			mexpr = new StructMemberExpr(realVar.varname,this.first.line,this.first.column)
            mexpr.var = realVar
            mexpr.member = varexpr.varname
			this.first = mexpr
			return true
		 }
	 }	
	 if type(this.first) == type(MemberExpr) {
		me = this.first
		return me.ismem(ctx)
	 }
	 if type(this.first) == type(FunCallExpr)
	 	return exprIsMtype(this.first,ctx)
	 return false
}
ChainExpr::compile(ctx,load)
{
	utils.debug("gen.ChainExpr::compile() ")
	this.record()
	
	if exprIsMtype(this.first,ctx)
		return this.memgen(ctx,load)

	return this.objgen(ctx,load)
}

ChainExpr::memgen(ctx,load)
{
	utils.debug("gen.ChainExpr::memgen()")
	if(type(this.last) == type(IndexExpr)){
		return this.indexgen(ctx,load)
	}
	curMember = null
	preStruct = null
	need_check = true
	if(type(this.first) == type(StructMemberExpr)){
		this.first.compile(ctx,false)
		s = this.first
		curMember = s.getMember()
		preStruct = curMember.parent
	}else if(type(this.first) == type(IndexExpr)){
		ie = this.first
		ie.compile_static(ctx,0)
		curMember = ie.ret
		preStruct = curMember.parent
	}else if type(this.first) == type(FunCallExpr){
		ie = this.first
		ie.compile(ctx,false)
		ie.check(ie.fcs != null,"static funcall not found fn signature")
		ti = ie.fcs.returnTypes[0]
		ie.check(ti.memType(),"should be static struct in chainexpr fncall")
		preStruct = ti.st
		need_check = false
	}else{
		this.check(false,"unsuport first type in chain")
	}
	lastn = this.last
	if type(this.last) == type(MemberCallExpr) {
		if lastn.tyassert != null
			need_check = false
	}else if type(this.last) == type(MemberExpr) {
		if lastn.tyassert != null
			need_check = false
	}
	if need_check
		this.check(curMember.isstruct,"field must be mem at chain expression in memgen")
	if curMember != null && (curMember.pointer || !need_check ) && !curMember.isarr{
		if type(this.first) != type(IndexExpr)
			compile.LoadMember(curMember)
	}
	for i : this.fields {
		this.check(type(i) == type(MemberExpr),"field must be member expression at mem chain expression")
		me = i
		this.check(curMember.structref != null,"must be memref in chain expr")
		s = curMember.structref
		curMember = s.getMember(me.membername)
		this.check(curMember != null,"mem not exist field:" + me.membername)
		this.check(curMember.isstruct,"middle field must be mem type in chain expression")

		compile.writeln("	add $%d, %%rax",curMember.offset)
		if curMember.pointer {
			compile.Load()
		}
	}
	this.check(this.last != null,"miss last field in chain expression")

	if type(this.last) == type(MemberExpr) {
		me = this.last
		ss = null

		if curMember == null {
			curMember = preStruct.getMember(me.membername)
			ss = curMember.parent
			this.check(ss == preStruct," not eq")
		}else {
			if me.tyassert != null {
				ss = me.tyassert.getStruct()
			}else{
				this.check(curMember.structref != null,"must be memref in chain expr")
				ss = curMember.structref
			}
			curMember = ss.getMember(me.membername)
		}
		this.check(curMember != null,"mem not exist field:" + me.membername)
		compile.writeln("	add $%d, %%rax",curMember.offset)
	}else if type(this.last) == type(MemberCallExpr) {
		lastn = this.last
		if lastn.tyassert != null {
			lastn.static_compile(ctx,lastn.tyassert.getStruct())
			return null
		}else {
			lastn.static_compile(ctx,curMember.structref)
			return null
		}
	}else{
		this.panic("chain invalid")
	}		

	if (type(this.last) != type(MemberCallExpr)) && load == true {
		compile.LoadMember(curMember)
	}

	ret = new StructMemberExpr("",this.line,this.column)
	ret.s = curMember.structref
	ret.m = curMember
	return ret
}

ChainExpr::objgen2(ctx,load)
{
	utils.debug("gen.ChainExpr::objgen()")
	this.record()
	for i = 0 ; i < std.len(this.fields) ; i += 1{
		expr = this.fields[i]
		if i == std.len(this.fields) - 1 {
			if type(expr) == type(FunCallExpr){
				fc = expr
				return fc.compile2(ctx,load,ast.ChainCall,null)
			}else
				return expr.compile(ctx, true)
		}else{
			expr.compile(ctx,true)
			compile.Push()
		}
	}
}
ChainExpr::objgen(ctx,load)
{
	utils.debug("gen.ChainExpr::objgen()")
	this.record()
	this.first.compile(ctx,true)
	compile.Push()

	for(i : this.fields){
		i.compile(ctx,true)
		compile.Push()
	}

	if type(this.last) == type(FunCallExpr) {
		return this.last.compile2(ctx,load, ast.ChainCall,null)
	}else {
		return this.last.compile(ctx,true)
	}
	this.panic("should not be here")
}

ChainExpr::assign(ctx , opt, rhs) {
	utils.debug("gen.ChainExpr::assign()")
	this.record()
    this.first.compile(ctx,true)
    compile.Push()
	for i : this.fields {
		i.compile(ctx,true)
		compile.Push()
	}
	if  type(this.last) == type(MemberExpr) {
		me  = this.last

		if type(rhs) == type(StackPosExpr) {
			rhs.pos = 1
			rhs.ismem = false
        }
        rhs.compile(ctx,true)
        compile.Push()
        internal.call_object_operator(opt,me.membername,"runtime_object_unary_operator2")
	}else if type(this.last) == type(IndexExpr) {
		this.last.assign(ctx,opt,rhs)
	}else{
		this.panic(this.toString(""))
	}
	return null
}

ChainExpr::memgen2(ctx,load)
{
	utils.debug("gen.ChainExpr::memgen()")
	preMember = null
	preStruct = null
	for i = 0 ; i < std.len(this.fields) ; i += 1{
		expr = this.fields[i]
		islast = i == std.len(this.fields) - 1

		curStruct = null
		curMember = null

		if(type(expr) == type(StructMemberExpr)){
			expr.compile(ctx,false)
			s = expr
			curMember = s.getMember()
			curStruct = curMember.parent

			if !islast && !curMember.isarr 
				compile.LoadMember(curMember)
			else if(islast && load)
				compile.LoadMember(curMember)

		}else if(type(expr) == type(IndexExpr)){
			tysize = 0
			if preMember != null
				tysize = preMember.size
			ie = expr
			ie.compile_static(ctx,tysize)
			curMember = ie.ret
			curStruct = curMember.parent
		}else if type(expr) == type(FunCallExpr){
			ie = expr
			ie.compile(ctx,false)
			ie.check(ie.fcs != null,"static funcall not found fn signature")
			ti = ie.fcs.returnTypes[0]
			ie.check(ti.memType(),"should be static struct in chainexpr fncall")
			curStruct = ti.st
			curMember = null
		} else if type(expr) == type(MemberExpr){
			me = expr
			if curMember == null {
				curMember = preStruct.getMember(me.membername)
				curStruct = curMember.parent
				this.check(curStruct == preStruct,"cur != pre")
			}else {
				if me.tyassert != null {
					curStruct = me.tyassert.getStruct()
				}else {
					this.check(curMember.structref != null , "must be memref in chain expr")
					curStruct = curMember.structref
				}
				curMember = curStruct.getMember(me.membername)
			}

			this.check(curMember != null,"memgen: mem not exist field2" + me.membername)

			compile.writeln("	add $%d, %rax",curMember.offset)
			if !islast && curMember.pointer {
				compile.LoadMember(curMember)
			}else if islast && load 
				compile.LoadMember(curMember)

		}else if type(expr) == type(MemberCallExpr) {
			mc = expr
			mfc = null
			if mc.tyassert != null {
				mfc = mc.static_compile(ctx,mc.tyassert.getStruct())
			}else {
				mfc = mc.static_compile(ctx,curMember.structref)
			}
			mc.check(mfc.fcs != null , "static funcall not signature")
			if std.len(mfc.fcs.returnTypes) > 0 {
				ti = mfc.fcs.returnTypes[0]
				mc.check(ti.memType(),"should be static struct in chainexpr fncall")
				curStruct = ti.st
				curMember = null
			}else {
				curStruct = null
				curMember = null
			}
		}else{
			this.check(false,"unsuport first type in chain")
		}
		mustStruct = expr.tyassert == null

		if curMember != null && mustStruct {
			this.check(curMember.isstruct,"field must be mem at chain expression in memgen")
		}
		preStruct = curStruct
		preMember = curMember
	}
	if preMember == null
		return null

	ret = new StructMemberExpr("",this.line,this.column)
	ret.s = preMember.structref
	ret.m = preMember
	return ret
}