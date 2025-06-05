use compiler.ast
use compiler.parser
use compiler.parser.package
use compiler.compile
use std
use compiler.utils

class ChainExpr   : ast.Ast {
    fields = [] // array[Ast] 
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

		match type(expr) {
			type(StructMemberExpr) : {
				expr.compile(ctx,false)
				s = expr
				curMember = s.getMember()
				curStruct = curMember.parent

				if !islast && !curMember.isarr 
					compile.LoadMember(curMember)
				else if(islast && load)
					compile.LoadMember(curMember)
			}
			type(IndexExpr): {
				ie = expr
				if ie.varname == "" || ie.varname == null {
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
			}
			type(FunCallExpr): {
				ie = expr
				ie.compile(ctx,false)
				ie.check(ie.fcs != null,"static funcall not found fn signature")
				ti = ie.fcs.returnTypes[0]
				ie.check(ti.memType(),"should be static struct in chainexpr fncall")
				curStruct = ti.st
				curMember = null
				if islast
					return expr
			}
			type(MemberExpr): {
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
			}
			type(MemberCallExpr): {
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
			}
			_ : {
				this.check(false,"unsuport first type in chain")
			}
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