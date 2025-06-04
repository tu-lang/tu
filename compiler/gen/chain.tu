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
    for(i : this.fields){
        str += "." + i.toString()
    }
    str += ")"
    return str
}

ChainExpr::ismem2(ctx) {
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

ChainExpr::ismem(ctx) {
	firstNode = this.fields[0]

	if(type(firstNode) == type(StructMemberExpr)) return true
	if(type(firstNode) == type(IndexExpr)) {
		return exprIsMtype(firstNode,ctx)
	}
	if type(firstNode) == type(VarExpr) {
		varexpr = firstNode
		realVar = varexpr.getVar(ctx,this)
		if realVar && !realVar.is_local && realVar.structtype {
			return true
		 }
	 }	
	 if type(firstNode) == type(MemberExpr) {
		me = firstNode
		return me.ismem(ctx)
	 }
	 if type(firstNode) == type(FunCallExpr)
	 	return exprIsMtype(firstNode,ctx)
	 return false
}

ChainExpr::compile(ctx,load)
{
	utils.debug("gen.ChainExpr::compile() ")
	this.record()
	
	if exprIsMtype(this.fields[0],ctx)
		return this.memgen(ctx,load)

	return this.objgen(ctx,load)
}

ChainExpr::memgen2(ctx,load)
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

ChainExpr::objgen(ctx,load)
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
ChainExpr::objgen2(ctx,load)
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
	for i = 0 ; i < std.len(this.fields) - 1; i += 1{
		expr = this.fields[i]
		expr.compile(ctx,true)
		compile.Push()
	}

	lastNode = std.tail(this.fields)
	if  type(lastNode) == type(MemberExpr) {
		me  = lastNode

		if type(rhs) == type(StackPosExpr) {
			rhs.pos = 1
			rhs.ismem = false
        }
        rhs.compile(ctx,true)
        compile.Push()
        internal.call_object_operator(opt,me.membername,"runtime_object_unary_operator2")
	}else if type(lastNode) == type(IndexExpr) {
		lastNode.assign(ctx,opt,rhs)
	}else{
		this.panic(this.toString(""))
	}
	return null
}

ChainExpr::memgen(ctx,load)
{
	utils.debug("gen.ChainExpr::memgen()")
	preMember = null
	preStruct = null
	for i = 0 ; i < std.len(this.fields) ; i += 1{
		expr = this.fields[i]
		islast = i == std.len(this.fields) - 1

		mustStruct = expr.tyassert == null

		if mustStruct && type(expr) == type(IndexExpr) {
			ie = expr
			if ie.varname == ""
				mustStruct = false
		}

		if preMember != null && mustStruct {
			this.check(preMember.isstruct,"field must be mem at chain expression in memgen")
		}

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
			ie = expr
			if ie.varname == "" {
				ie.compile_static(ctx,preMember.size)
				curMember = preMember.clone()
				if !curMember.isarr && curMember.pointer {
					curMember.pointer = false
				}
				curStruct = curMember.parent
			}else {
				ie.compile_static(ctx,0)
				curMember = ie.ret
				curStruct = curMember.parent
			}
			if !islast && curMember.pointer && ie.varname == "" {
				compile.LoadSize(curMember.size,curMember.isunsigned)
			}else if(islast && load){
				compile.LoadSize(curMember.size,curMember.isunsigned)
			}
		}else if type(expr) == type(FunCallExpr){
			ie = expr
			ie.compile(ctx,false)
			ie.check(ie.fcs != null,"static funcall not found fn signature")
			ti = ie.fcs.returnTypes[0]
			ie.check(ti.memType(),"should be static struct in chainexpr fncall")
			curStruct = ti.st
			curMember = null
			if islast
				return expr
		} else if type(expr) == type(MemberExpr){
			me = expr
			if preMember == null {
				me.check(preStruct != null,"member not struct field")
				curMember = preStruct.getMember(me.membername)
				curStruct = curMember.parent
				this.check(curStruct == preStruct,"cur != pre")
			}else {
				if me.tyassert != null {
					curStruct = me.tyassert.getStruct()
				}else {
					this.check(preMember.structref != null , "must be memref in chain expr")
					curStruct = preMember.structref
				}
				curMember = curStruct.getMember(me.membername)
			}

			this.check(curMember != null,"memgen: mem not exist field2" + me.membername)

			compile.writeln("	add $%d, %rax",curMember.offset)
			if !islast && curMember.pointer && !curMember.isarr {
				compile.LoadMember(curMember)
			}else if islast && load 
				compile.LoadMember(curMember)

		}else if type(expr) == type(MemberCallExpr) {
			mc = expr
			mfc = null
			st = null
			if mc.tyassert != null {
				st = mc.tyassert.getStruct()
			}else {
				if preMember != null
					st = preMember.structref
				else 
					st = preStruct
			}
			mfc = mc.static_compile(ctx,st)
			mc.check(mfc.fcs != null , "static funcall not signature")
			if islast
				return mfc
			if std.len(mfc.fcs.returnTypes) > 0 {
				ti = mfc.fcs.returnTypes[0]
				if !islast
					mc.check(ti.memType(),"should be static struct in chainexpr fncall")
				if ti.memType(){
					curStruct = ti.st
					curMember = null
				}
			}else {
				curStruct = null
				curMember = null
			}
		}else{
			this.check(false,"unsuport first type in chain")
		}

		preStruct = curStruct
		preMember = curMember
	}
	if preMember == null{
		this.check(false,"not should be here")
		return null
	}

	ret = new StructMemberExpr("",this.line,this.column)
	ret.s = preMember.structref
	ret.m = preMember
	return ret
}