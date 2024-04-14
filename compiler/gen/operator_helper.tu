use compiler.ast
use compiler.compile
use compiler.utils
use compiler.parser
use compiler.internal

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
	dx = "%rdx"
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
		ty = this.lhs.getType(this.ctx)
		if ast.isfloattk(ty)
			compile.Pushf(ty)
		else 
			compile.Push()
	}
	
	if this.rhs && this.opt != ast.LOGAND && this.opt != ast.LOGOR 
		this.genRight(false,this.rhs) 
	if this.ltypesize != 8 {
		this.ax = "%eax"
		this.di = "%edi"
		this.dx = "%edx"
	}
	if this.floatop(){
		this.ax = "%xmm0"
		this.di = "%xmm1"
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

	if this.floatop() {
		if this.opt == ast.ASSIGN {
			compile.Cast(this.rtoken,this.ltoken)
		}else{
			rettoken = utils.max(this.ltoken,this.rtoken)
			compile.Cast(rettoken,this.ltoken)
		}
		if this.ltoken == ast.F32 || this.ltoken == ast.F64
			compile.Storef(this.ltoken)
		else 
			compile.Store(this.ltypesize)
		return null
	}

	compile.Store(this.ltypesize)
	return null
}
OperatorHelper::binary()
{
	utils.debug("gen.OperatorHelper::binary()")
	base = utils.max(this.rtoken,this.ltoken)

	if !this.rhs {
		if ast.isfloattk(this.ltoken) compile.Popf(this.ltoken)
		else  compile.Pop("%rax")

		match this.opt {
			ast.LOGNOT: {
				if ast.isfloattk(this.ltoken)
					compile.CreateFCmp(this.ltoken)
				else
					compile.CreateCmp(this.ltypesize)

				compile.writeln("	sete %%al")
				compile.writeln("	movzx %%al, %%rax")
				return null
			}
			ast.BITNOT: {
				if ast.isfloattk(this.ltoken) {
					this.lhs.check(false,"unsupport bitnot in float expression")
				}

				compile.writeln("	not %%rax")
				return null
			}
			_ :	this.lhs.panic("asmgen: must !,~ at unary expression,not " + ast.getTokenString(this.opt))
		}
	}
	if this.opt == ast.ASSIGN return null
	if this.opt != ast.LOGAND && this.opt != ast.LOGOR  {
		// tke = fmt.sprintf("token_max(lhs,rhs) should in(i8,u64) ltoken:%d rtoken:%d\n %s\n %s\n",
				// int(this.ltoken),int(this.rtoken),this.lhs.toString(),this.rhs.toString()
		// )
		tke = "token_max should in i8-u64"
		this.lhs.check(base >= ast.I8 && base <= ast.F64,tke)
		compile.Cast(this.rtoken,base)
		if ast.isfloattk(base)	
			 compile.writeln("	movsd %%xmm0 , %%xmm1")
		else compile.writeln("	mov %%rax, %%rdi") 
		if ast.isfloattk(this.ltoken) 
			compile.Popf(this.ltoken)
		else compile.Pop("%rax")
		compile.Cast(this.ltoken,base)
	}

	this.checkfloatop()
	
	match this.opt {
		ast.ADD_ASSIGN | ast.ADD:	compile.writeln("	add%s %s, %s", this.floatopsuffix(),this.di, this.ax)
		ast.SUB_ASSIGN | ast.SUB:	compile.writeln("	sub%s %s,%s", this.floatopsuffix(),this.di,this.ax)
		ast.MUL_ASSIGN | ast.MUL:	{
			if ast.isfloattk(base)
				compile.writeln("	mul%s %s,%s",this.floatopsuffix(), this.di,this.ax)
			else 
				compile.writeln("	imul %s,%s",this.di,this.ax)
		}
		ast.BITXOR_ASSIGN | ast.BITXOR : {
			if (this.ax == "%eax") 
				compile.writeln("	xorl %s,%s",this.di,this.ax)
			else 
				compile.writeln("	xor %s,%s",this.di,this.ax)
		}
		ast.BITAND | ast.BITAND_ASSIGN:	compile.writeln("	and %s,%s",this.di,this.ax)
		ast.BITOR  | ast.BITOR_ASSIGN:	compile.writeln("	or %s,%s",this.di,this.ax)

		ast.DIV_ASSIGN | ast.DIV | ast.MOD_ASSIGN | ast.MOD : {
			if ast.isfloattk(base)
				compile.writeln("	div%s %s,%s",this.floatopsuffix(),this.di,this.ax)
			else if this.lisunsigned {
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
			if ast.isfloattk(base) return this.floatcmp()

			cmp = "sete"
			match this.opt {
				ast.EQ : {
					if this.lisunsigned cmp = "setz"
					else            cmp = "sete"
				}
				ast.NE : {
					if this.lisunsigned cmp = "setnz"
					else            cmp = "setne"
				}
				ast.LE : {
					if this.lisunsigned cmp = "setbe"
					else            cmp = "setle"
				}
				ast.LT : {
					if this.lisunsigned cmp = "setb"
					else			cmp = "setl"
				}
				ast.GE : {
					if this.lisunsigned cmp = "setae"
					else			cmp = "setge"
				}
				ast.GT : {
					if this.lisunsigned cmp = "seta"
					else			cmp = "setg"
				}
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
			compile.writeln("	jne %s.L.true.%d", compile.currentParser.label(),c)

			this.genRight(false,this.rhs)	
			if this.rtypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	jne %s.L.true.%d",compile.currentParser.label(), c)
			compile.writeln("	mov $0, %%rax")
			compile.writeln("	jmp %s.L.end.%d",compile.currentParser.label(), c)
			compile.writeln("%s.L.true.%d:",compile.currentParser.label(), c)
			compile.writeln("	mov $1, %%rax")
			compile.writeln("%s.L.end.%d:",compile.currentParser.label(), c)
		}
		ast.LOGAND : { 
			c = ast.incr_labelid()
			
			compile.Pop("%rax")	
			if this.ltypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	je %s.L.false.%d", compile.currentParser.label(),c)

			this.genRight(false,this.rhs)	
			if this.rtypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	je %s.L.false.%d",compile.currentParser.label(), c)
			compile.writeln("	mov $1, %%rax")
			compile.writeln("	jmp %s.L.end.%d",compile.currentParser.label(), c)
			compile.writeln("%s.L.false.%d:", compile.currentParser.label(),c)
			compile.writeln("	mov $0, %%rax")
			compile.writeln("%s.L.end.%d:", compile.currentParser.label(),c)
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
				if m.isstruct tk = ast.U64
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
				this.lhs.panic(fmt.sprintf(
						"not VarExpr,only support *(class var) = expression :%s %d\n",
						this.lhs.toString(),
						this.lhs.line
					)
				)
			rv = ret
			if !rv.structtype
				this.lhs.panic(
					fmt.sprintf(
						"not structtype,only support *(class var) = expression :%s\n",
						this.lhs.toString()
					)
				)
			
			this.initcond(true,rv.size,rv.type,rv.pointer)
			return rv
		}
		type(ChainExpr) : {
			ce = this.lhs
			ce.compile(this.ctx)
			m = ce.ret
			this.lmember = m
			
			tk = m.type
			if m.isstruct tk = ast.U64
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
				this.lhs.panic(
					fmt.sprintf(
						"genLeft: lhs not structExpr %s \n",
						this.lhs.toString()
					)
				)
			
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
	match type(expr) {
		type(IntExpr) : {
			ie = expr	
			compile.writeln("	mov $%s,%%rax",ie.lit)
			this.initcond(isleft,8,ast.I64,false)
			return ie
		}
		type(FloatExpr) : {
			compile.writeln("	mov $%d,%%rax",expr.lit)
			compile.writeln("	movq %%rax , %%xmm0")
			this.initcond(isleft,8,ast.F64,false)
			return expr
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
	
	ret = expr.compile(this.ctx)
	
	if !exprIsMtype(expr,this.ctx) && ( this.opt == ast.LOGAND || this.opt == ast.LOGOR) {
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

			trtoken = ast.U64
			if this.rhs != null
				trtoken = this.rhs.getType(this.ctx)
			if isleft && ast.isfloattk(trtoken) {
				size = parser.typesize[int(trtoken)]
				this.initcond(isleft,size,trtoken,false)
			}else if(!isleft && ast.isfloattk(this.ltoken)){
				size = parser.typesize[int(this.ltoken)]
				this.initcond(isleft,size,this.ltoken,false)
			}else{
				this.initcond(isleft,8,ast.U64,false)
			}
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
		if ast.isfloattk(v.type)
			this.initcond(isleft,parser.typesize[int(ast.I64)],v.type,false)
		else if !v.structtype
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
		if v.isstruct tk = ast.U64
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
OperatorHelper::floatop(){
	m = utils.max(this.ltoken,this.rtoken)
	if m == ast.F32 || m == ast.F64
		return true
	return false
}

OperatorHelper::floatopsuffix(){
	base = utils.max(this.ltoken , this.rtoken)
	if base == ast.F32
		return "ss"
	if base == ast.F64
		return "sd"
	return ""
}

OperatorHelper::checkfloatop(){
	base = this.ltoken
	if this.rhs != null
		base = utils.max(this.ltoken,this.rtoken)

	if base != ast.F32 && base != ast.F64 {
		return null
	}
	match this.opt {
		ast.EQ | ast.NE | ast.LE | ast.LT | ast.GE | ast.GT : return true
		ast.ADD | ast.ADD_ASSIGN: return true
		ast.SUB | ast.SUB_ASSIGN: return true
		ast.MUL | ast.MUL_ASSIGN: return true
		ast.DIV | ast.DIV_ASSIGN: return true
		_ : this.lhs.check(false,"unsupport op for float in " + ast.getTokenString(this.opt))
	}
}

OperatorHelper::floatcmp(){
	ori = this.ax
	dst = this.di
	if this.opt == ast.GE || this.opt == ast.GT {
		ori = this.di
		dst = this.ax
	}
	compile.writeln(
		"	ucomi%s %s, %s",
		this.floatopsuffix(),
		ori,dst
	)
	match this.opt {
		ast.EQ: {
			compile.writeln("	sete %%al")
			compile.writeln("	setnp %%dl")
			compile.writeln("	and %%dl, %%al")
		}
		ast.NE: {
			compile.writeln("	setne %%al")
			compile.writeln("	setp %%dl")
			compile.writeln("	or %%dl, %%al")
		}
		ast.LE:	compile.writeln("setae %%al")
		ast.LT: compile.writeln("seta %%al")
		ast.GE: compile.writeln("setae %%al")
		ast.GT: compile.writeln("seta %%al")
		_: this.lhs.check(false,"unsupport cmp op in float")
	}
	compile.writeln("	and $1 , %%al")
	compile.writeln("	movzb %%al , %%rax")
	return null
}

OperatorHelper::astcheck(){
	if this.opt == ast.LOGOR || this.opt == ast.LOGAND {
		if exprIsMtype(this.lhs,this.ctx) && type(this.lhs) != type(BinaryExpr) {
			this.lhs = toBinExpr(this.lhs)
		}
		if(
			this.rhs != null && 
			exprIsMtype(this.rhs,this.ctx) && 
			type(this.rhs) != type(BinaryExpr)
			){
			this.rhs = toBinExpr(this.rhs)
		}
	}
}