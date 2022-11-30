use ast
use compile
use utils
use parser

class OperatorHelper {
	ctx # [Context]
	lhs rhs # lhs rhs
	opt

	var 

	//left
	ltypesize   = 8
	lvarsize    = 1
	ltoken      = ast.I8
	lisunsigned = false
	lmember     = null
	lispointer  = false
	//right
	rtypesize
	rvarsize
	rtoken
	risunsigned
	rispointer


	ax = "%rax"
	di = "%rdi"
	dx = "$rdx"
	needassign = false
}
OperatorHelper::init(ctx,lhs,rhs,opt) {
	this.ctx = ctx
	this.lhs = lhs
	this.rhs = rhs
	this.opt = opt
	if opt >= ast.ASSIGN && opt <= ast.BITOR_ASSIGN
		this.needassign = true
}

OperatorHelper::memoryOp(lhs,rhs)
{
	return true
}
OperatorHelper::gen()
{
	utils.debug("gen.OperatorHelpler::gen()")
	if this.needassign {
		this.genLeft()
		compile.Push()
		
		if this.opt != ast.ASSIGN {
			if this.lmember compile.LoadMember(this.lmember)
			else        compile.LoadSize(this.ltypesize,this.lisunsigned)
			compile.Push()
		}
	} else {
		this.genRight(true,this.lhs)
		compile.Push()
	}
	
	if this.rhs && this.opt != ast.LOGAND && this.opt != ast.LOGOR 
		this.genRight(false,this.rhs) 
	if this.ltypesize != 8 {
		this.ax = "%eax"
		this.di = "%edi"
		this.dx = "%edx"
	}
	if this.needassign return this.assign()
	else {
		ret = this.binary()
		if this.di == "%edi" {
			compile.Cast(ast.I32,ast.I64)
		}
		return ret
	}
	return null
}
OperatorHelper::assign()
{
	utils.debug("gen.OperatorHelper::assign()")
	ret = this.binary()
	if !this.needassign return ret
	if this.lmember && this.lmember.bitfield
	{
		compile.writeln("	mov %%rax, %%rdi")
		//NOTICE: 1L << bitwidth - 1
		compile.writeln("   and $%d, %%rdi", (1 << this.lmember.bitwidth) - 1)
		compile.writeln("	shl $%d, %%rdi", this.lmember.bitoffset)
		compile.writeln("   mov (%%rsp), %%rax")
		compile.LoadSize(this.lmember.size,this.lmember.isunsigned)
		//FIXME: mask = ((1L << lmember.bitwidth) - 1) << lmember.bitoffset
		mask = ((1 << this.lmember.bitwidth) - 1) << this.lmember.bitoffset
		compile.writeln("  mov $%d, %%r9", ~mask)
		compile.writeln("  and %%r9, %%rax")
		compile.writeln("  or %%rdi, %%rax")
	}
	
	if type(this.lhs) == type(DelRefExpr) {
		compile.Cast(this.rtoken,this.ltoken)
		compile.Store(this.lvarsize)
		return null
	}else if type(this.lhs) == type(ChainExpr) {
		i = this.lhs
		if type(i.last) == type(IndexExpr) {
			compile.Cast(this.rtoken,this.ltoken)
			compile.Store(this.lvarsize)
			return null
		}
	}
	compile.Store(this.ltypesize)
	return null
}
OperatorHelper::binary()
{
	utils.debug("gen.OperatorHelper::binary()")
	if !this.rhs {
		compile.Pop("%rax")
		match this.opt {
			ast.LOGNOT: {
				compile.CreateCmp(this.ltypesize)
				compile.writeln("	sete %%al")
				compile.writeln("	movzx %%al, %%rax")
				return null
			}
			ast.BITNOT: {
				compile.writeln("	not %%rax")
				return null
			}
			_ :	this.lhs.panic("asmgen: must !,~ at unary expression,not %s\n",ast.getTokenString(this.opt))
		}
	}
	if this.opt == ast.ASSIGN return null
	if this.opt != ast.LOGAND && this.opt != ast.LOGOR  {
		base = utils.max(this.rtoken,this.ltoken)
		// tke = fmt.sprintf("token_max(lhs,rhs) should in(i8,u64) ltoken:%d rtoken:%d\n %s\n %s\n",
				// int(this.ltoken),int(this.rtoken),this.lhs.toString(),this.rhs.toString()
		// )
		tke = "token_max should in i8-u64"
		this.lhs.check(base >= ast.I8 && base <= ast.U64,tke)
		compile.Cast(this.rtoken,base)
		compile.writeln("	mov %%rax,%%rdi")
		compile.Pop("%rax")
		compile.Cast(this.ltoken,base)
	}
	
	match this.opt {
		ast.ADD_ASSIGN | ast.ADD:	compile.writeln("	add %s, %s", this.di, this.ax)
		ast.SUB_ASSIGN | ast.SUB:	compile.writeln("	sub %s,%s",this.di,this.ax)
		ast.MUL_ASSIGN | ast.MUL:	compile.writeln("	imul %s,%s",this.di,this.ax)
		ast.BITXOR_ASSIGN | ast.BITXOR : {
			if (this.ax == "%eax") 
				compile.writeln("	xorl %s,%s",this.di,this.ax)
			else 
				compile.writeln("	xor %s,%s",this.di,this.ax)
		}
		ast.BITAND | ast.BITAND_ASSIGN:	compile.writeln("	and %s,%s",this.di,this.ax)
		ast.BITOR  | ast.BITOR_ASSIGN:	compile.writeln("	or %s,%s",this.di,this.ax)

		ast.DIV_ASSIGN | ast.DIV | ast.MOD_ASSIGN | ast.MOD : {
			if this.lisunsigned {
				compile.writeln("	mov $0,%s",this.dx)
				compile.writeln("	div %s",this.di)
			}else{
				if this.ltypesize == 8	compile.writeln("	cqo")
				else				compile.writeln("	cdq")
				compile.writeln("	idiv %s",this.di)
			}
			if this.opt == ast.MOD_ASSIGN || this.opt == ast.MOD
      			compile.writeln("	mov %%rdx, %%rax")
		}
		ast.EQ | ast.NE | ast.LE | ast.LT | ast.GE | ast.GT: {
			cmp = "sete"
			match this.opt {
				ast.EQ : cmp = "sete"
				ast.NE : cmp = "setne"
				ast.LE : {
					if this.lisunsigned cmp = "setbe"
					else            cmp = "setle"
				}
				ast.LT : {
					if this.lisunsigned cmp = "setb"
					else			cmp = "setl"
				}
				ast.GE : cmp = "setge"
				ast.GT : cmp = "setg"
			}
			
			compile.writeln("	cmp %s,%s",this.di,this.ax)
			compile.writeln("	%s %%al",cmp)
			compile.writeln("	movzb %%al, %%rax")
		}
		ast.SHL_ASSIGN | ast.SHL : {
    		compile.writeln("	mov %%rdi, %%rcx")
    		compile.writeln("	shl %%cl, %s", this.ax)
		}
		ast.SHR_ASSIGN | ast.SHR : {
    		compile.writeln("	mov %%rdi, %%rcx")
			if this.lisunsigned	compile.writeln("	shr %%cl, %s", this.ax)
    		else			compile.writeln("	sar %%cl, %s", this.ax)
		}
		ast.LOGOR : { 
			c = ast.incr_labelid()
			compile.Pop("%rax")	
			if this.ltypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	jne .L.true.%d", c)

			this.genRight(false,this.rhs)	
			if this.rtypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	jne .L.true.%d", c)
			compile.writeln("	mov $0, %%rax")
			compile.writeln("	jmp .L.end.%d", c)
			compile.writeln(".L.true.%d:", c)
			compile.writeln("	mov $1, %%rax")
			compile.writeln(".L.end.%d:", c)
		}
		ast.LOGAND : { 
			c = ast.incr_labelid()
			
			compile.Pop("%rax")	
			if this.ltypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	je .L.false.%d", c)

			this.genRight(false,this.rhs)	
			if this.rtypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	je .L.false.%d", c)
			compile.writeln("	mov $1, %%rax")
			compile.writeln("	jmp .L.end.%d", c)
			compile.writeln(".L.false.%d:", c)
			compile.writeln("	mov $0, %%rax")
			compile.writeln(".L.end.%d:", c)
		}
	}
	return null
}

OperatorHelper::genLeft()
{
    utils.debugf("gen.OpHelper::genLeft()")
	var = this.var
	match type(this.lhs) {
		type(DelRefExpr) : {
			dr = this.lhs
			ret = dr.expr.compile(this.ctx)

			if type(ret) == type(ChainExpr) {
				ce = ret
				m = ce.ret
				if m.pointer compile.Load()
				this.lmember = m
				tk = m.type
				if m.isclass tk = ast.U64
				this.initcond(true,m.size,tk,m.pointer)
				return ce
			}else if type(ret) == type(StructMemberExpr) {
				smember = ret
				m = smember.getMember()
				compile.LoadMember(m)
				lmember = m
				this.initcond(true,m.size,m.type,m.pointer)
				return smember
			}

			if ret == null || type(ret) != type(VarExpr) 
				this.lhs.panic("not VarExpr,only support *(class var) = expression :%s %d\n",this.lhs.toString(),this.lhs.line)
			rv = ret
			if !rv.structtype
				this.lhs.panic("not structtype,only support *(class var) = expression :%s\n",this.lhs.toString())
			
			this.initcond(true,rv.size,rv.type,rv.pointer)
			return rv
		}
		type(ChainExpr) : {
			ce = this.lhs
			ce.compile(this.ctx)
			m = ce.ret
			this.lmember = m
			
			tk = m.type
			if m.isclass tk = ast.U64
			this.initcond(true,m.size,tk,m.pointer)
			return ce
		}
		type(StructMemberExpr) : {
			smember = this.lhs
			smember.compile(this.ctx)
			m = smember.getMember()
			this.lmember = m
			this.initcond(true,m.size,m.type,m.pointer)
			return smember
		}
		type(VarExpr) : {
			if !var.structtype
				this.lhs.panic("genLeft: lhs not structExpr %s \n",this.lhs.toString())
			
			this.initcond(true,var.size,var.type,var.pointer)
			compile.GenAddr(var)
			return var
		}
		_ : this.lhs.panic("genLeft: unknow left type")
	}
}
OperatorHelper::genRight(isleft,expr)
{
    utils.debugf("gen.OpHelper::genRight()")
	match type(this.expr) {
		type(IntExpr) : {
			ie = expr	
			compile.writeln("	mov $%s,%%rax",ie.lit)
			this.initcond(isleft,8,ast.I64,false)
			return ie
		}
		type(StringExpr): {
			ie = expr
			compile.writeln("	lea %s(%%rip), %%rax",ie.name)
			this.initcond(isleft,8,ast.U64,true)
			return ie
		}
		type(CharExpr):{
			ie = expr
			compile.writeln("	mov $%s,%%rax",ie.lit)
			this.initcond(isleft,8,ast.I64,false)
			return ie
		}
		type(BoolExpr):{
			ie = expr
			compile.writeln("	mov $%d,%%rax",ie.lit)
			this.initcond(isleft,8,ast.I64,false)
			return ie
		}
		type(NullExpr) : {
			compile.writeln("	mov $0,%%rax")
			this.initcond(isleft,8,ast.I64,false)
			return null
		}
	}
	
	exist<i64> = expr.compile(this.ctx)
	if exist == 0 {
		expr.check(false,"return value is Null")
	}
	ret = exist

	if !exprIsMtype(expr,this.ctx) && ( this.op == ast.LOGAND || this.opt == ast.LOGOR) {
		internal.isTrue()
	}
	match type(expr) {
		type(BinaryExpr) | type(AssignExpr) : {
			t = expr.getType(this.ctx)
			size = parser.typesize[int(t)]
			this.initcond(isleft,size,t,false)
			return ret
		}
		type(AddrExpr) : {
			this.initcond(isleft,8,ast.U64,true)
			return ret
		}
		type(FunCallExpr) : {
			this.initcond(isleft,8,ast.U64,false)
			return ret
		}
		type(BuiltinFuncExpr) : {
			this.initcond(isleft,8,ast.U64,false)
			return ret
		}
	}
	
	if ret == null{
		this.initcond(isleft,8,ast.U64,false)
	}else if type(ret) == type(NewExpr) || type(ret) == type(NewStructExpr) {
		this.initcond(isleft,8,ast.U64,false)
	}else if type(ret) == type(VarExpr) 
	{
		v = ret
		if !v.structtype
			this.initcond(isleft,8,ast.I64,false)
		else
			this.initcond(isleft,v.size,v.type,v.pointer)
	}else if type(ret) == type(IndexExpr)
	{
		member = ret.ret
		if(member == null)
			this.initcond(isleft,8,ast.U64,false)
		else
			this.initcond(isleft, member.size,member.type,member.pointer)
	}else if type(ret) == type(StructMemberExpr) 
	{
		m = ret
		v = m.getMember() 
		this.initcond(isleft,v.size,v.type,v.pointer)
		
		if type(expr) != type(AddrExpr) && type(expr) != type(DelRefExpr){
			compile.LoadMember(v)
		}
	}else if type(ret) == type(ChainExpr) {
		m = ret
		v = m.ret
		tk = v.type
		if v.isclass tk = ast.U64
		this.initcond(isleft,v.size,tk,v.pointer)
		
		if type(expr) == type(AddrExpr) {
			
		}else if type(expr) == type(DelRefExpr) {
			compile.LoadSize(v.size,v.isunsigned)
		}else if type(m.last) == type(IndexExpr) {
			compile.LoadSize(v.size,v.isunsigned)
		}else if type(m.last) == type(MemberCallExpr) {
		}else{
			compile.LoadMember(v)
		}
	}else{
		ret.check(false,fmt.sprintf("not allowed expression in memory operator:%s" + ret.toString()))
	}
	return ret
}

OperatorHelper::initcond(left,varsize,type,ispointer) 
{
	typesize = varsize
	if ispointer typesize = 8
	
	isunsigned = ast.type_isunsigned(type)

	if left {
		this.ltypesize = typesize
		this.lvarsize  = varsize
		this.ltoken    = type
		this.lisunsigned = isunsigned
		this.lispointer  = ispointer
		if ispointer this.ltoken = ast.U64
		return null
	}
	this.rtypesize = typesize
	this.rvarsize  = varsize
	this.rtoken    = type
	this.risunsigned = isunsigned
	this.rispointer  = ispointer
	if ispointer this.rtoken = ast.U64

}