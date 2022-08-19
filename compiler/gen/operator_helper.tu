use ast
use compile

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
	if opt >= ASSIGN && opt <= BITOR_ASSIGN
		this.needassign = true
}

OperatorHelper::memoryOp(lhs,rhs)
{
	return true
}
OperatorHelper::gen()
{
	if needassign {
		genLeft()
		compile.Push()
		
		if opt != ASSIGN {
			if lmember compile.LoadMember(lmember)
			else        compile.LoadSize(ltypesize,lisunsigned)
			compile.Push()
		}
	} else {
		genRight(true,lhs)
		compile.Push()
	}
	
	if this.rhs && this.opt != ast.LOGAND && this.opt != ast.LOGOR 
		genRight(false,rhs) 
	if ltypesize != 8 {
		ax = "%eax"
		di = "%edi"
		dx = "%edx"
	}
	if needassign return assign()
	else	 	   return binary()
}
OperatorHelper::assign()
{
	ret = binary()
	if !needassign return ret
	if lmember && lmember.bitfield
	{
		compile.writeln("	mov %%rax, %%rdi")
		//NOTICE: 1L << bitwidth - 1
		compile.writeln("   and $%I, %%rdi", (1 << lmember.bitwidth) - 1)
		compile.writeln("	shl $%d, %%rdi", lmember.bitoffset)
		compile.writeln("   mov (%%rsp), %%rax")
		compile.LoadSize(lmember.size,lmember.isunsigned)
		//FIXME: mask = ((1L << lmember.bitwidth) - 1) << lmember.bitoffset
		mask = ((1 << lmember.bitwidth) - 1) << lmember.bitoffset
		compile.writeln("  mov $%I, %%r9", ~mask)
		compile.writeln("  and %%r9, %%rax")
		compile.writeln("  or %%rdi, %%rax")
	}
	
	if type(lhs) == type(ast.DelRefExpr) {
		compile.Cast(rtoken,ltoken)
		compile.Store(lvarsize)
		return null
	}
	compile.Store(ltypesize)
}
OperatorHelper::binary()
{
	if !this.rhs {
		compile.Pop("%rax")
		match opt {
			ast.LOGNOT: {
				compile.CreateCmp(ltypesize)
				compile.writeln("	sete %%al")
				compile.writeln("	movzx %%al, %%rax")
				return null
			}
			ast.BITNOT: {
				compile.writeln("	not %%rax")
				return null
			}
			_ :	this.lhs.panic("asmgen: must !,~ at unary expression,not %s\n",getTokenString(opt))
		}
	}
	if this.opt == ast.ASSIGN return null
	if this.opt != ast.LOGAND && this.opt != ast.LOGOR  {
		Token base = max(rtoken,ltoken)
		tke = fmt.sprintf("token_max(lhs,rhs) should in(i8,u64) ltoken:%s rtoken:%s\n %s\n %s\n",
				ltoken,rtoken,lhs.toString(),rhs.toString()
		)
		this.lhs.check(base >= ast.I8 && base <= ast.U64,tke)
		
		compile.Cast(rtoken,base)
		compile.writeln("	mov %%rax,%%rdi")
		compile.Pop("%rax")
		compile.Cast(ltoken,base)
	}
	
	match opt {
		ast.ADD_ASSIGN | ast.ADD:	compile.writeln("	add %s, %s", di, ax)
		ast.SUB_ASSIGN | ast.SUB:	compile.writeln("	sub %s,%s",di,ax)
		ast.MUL_ASSIGN | ast.MUL:	compile.writeln("	imul %s,%s",di,ax)
		ast.BITAND | ast.BITAND_ASSIGN:	compile.writeln("	and %s,%s",di,ax)
		ast.BITOR  | ast.BITOR_ASSIGN:	compile.writeln("	or %s,%s",di,ax)

		ast.DIV_ASSIGN | ast.DIV | ast.MOD_ASSIGN | ast.MOD : {
			if lisunsigned {
				compile.writeln("	mov $0,%s",dx)
				compile.writeln("	div %s",di)
			}else{
				if ltypesize == 8	compile.writeln("	cqo")
				else				compile.writeln("	cdq")
				compile.writeln("	idiv %s",di)
			}
			if opt == ast.MOD_ASSIGN || opt == ast.MOD
      			compile.writeln("	mov %%rdx, %%rax")
		}
		ast.EQ | ast.NE | ast.LE | ast.LT | ast.GE | ast.GT: {
			cmp = "sete"
			match opt {
				ast.EQ : cmp = "sete"
				ast.NE : cmp = "setne"
				ast.LE : {
					if lisunsigned cmp = "setbe"
					else            cmp = "setle"
				}
				ast.LT : {
					if lisunsigned cmp = "setb"
					else			cmp = "setl"
				}
				ast.GE : cmp = "setge"
				ast.GT : cmp = "setg"
			}
			
			compile.writeln("	cmp %s,%s",di,ax)
			compile.writeln("	%s %%al",cmp)
			compile.writeln("	movzb %%al, %%rax")
		}
		ast.SHL_ASSIGN | ast.SHL : {
    		compile.writeln("	mov %%rdi, %%rcx")
    		compile.writeln("	shl %%cl, %s", ax)
		}
		ast.SHR_ASSIGN | ast.SHR : {
    		compile.writeln("	mov %%rdi, %%rcx")
			if lisunsigned	compile.writeln("	shr %%cl, %s", ax)
    		else			compile.writeln("	sar %%cl, %s", ax)
		}
		ast.LOGOR : { 
			c = ast.incr_labelid()
			compile.Pop("%rax")	
			if ltypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	jne .L.true.%d", c)

			this.genRight(false,rhs)	
			if rtypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	jne .L.true.%d", c)
			compile.writeln("	mov $0, %%rax")
			compile.writeln("	jmp .L.end.%d", c)
			compile.writeln(".L.true.%d:", c)
			compile.writeln("	mov $1, %%rax")
			compile.writeln(".L.end.%d:", c)
			break
		}
		ast.LOGAND : { 
			c = ast.incr_labelid()
			
			compile.Pop("%rax")	
			if ltypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	je .L.false.%d", c)

			this.genRight(false,rhs)	
			if rtypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	je .L.false.%d", c)
			compile.writeln("	mov $1, %%rax")
			compile.writeln("	jmp .L.end.%d", c)
			compile.writeln(".L.false.%d:", c)
			compile.writeln("	mov $0, %%rax")
			compile.writeln(".L.end.%d:", c)
			break
		}
	}
	return null
}

OperatorHelper::genLeft()
{
	match type(lhs) {
		type(ast.DelRefExpr) : {
			dr = lhs
			ret = dr.expr.compile(ctx)

			if type(ret) == type(ast.ChainExpr) {
				ce = ret
				m = ce.ret
				if m.pointer compile.Load()
				lmember = m
				tk = m.type
				if m.isclass tk = ast.U64
				initcond(true,m.size,tk,m.pointer)
				return ce
			}

			if ret == null || type(ret) != type(ast.VarExpr) 
				parse_err("not VarExpr,only support *(class var) = expression :%s %d\n",lhs.toString(),lhs.line)
			rv = ret
			if !rv.structtype
				parse_err("not structtype,only support *(class var) = expression :%s\n",lhs.toString())
			
			initcond(true,rv.size,rv.type,rv.pointer)
			return rv
		}
		type(ast.ChainExpr) : {
			ce = lhs
			ce.compile(ctx)
			m = ce.ret
			lmember = m
			
			tk = m.type
			if m.isclass tk = ast.U64
			initcond(true,m.size,tk,m.pointer)
			return ce
		}
		type(ast.StructMemberExpr) : {
			smember = lhs
			smember.compile(ctx)
			m = smember.getMember()
			lmember = m
			initcond(true,m.size,m.type,m.pointer)
			return smember
		}
		type(ast.VarExpr) : {
			if !var.structtype
				lhs.panic("genLeft: lhs not structExpr %s \n",lhs.toString())
			
			initcond(true,var.size,var.type,var.pointer)
			compile.GenAddr(var)
			return var
		}
		_ : parse_err("genLeft: unknow left type")
	}
}
OperatorHelper::genRight(isleft,expr)
{
	match type(this.expr) {
		type(IntExpr) : {
			ie = expr	
			compile.writeln("	mov $%s,%%rax",ie.lit)
			initcond(isleft,8,I64,false)
			return ie
		}
		type(StringExpr): {
			ie = expr
			writeln("	lea %s(%%rip), %%rax",ie.name)
			initcond(isleft,8,U64,true)
			return ie
		}
		type(NullExpr) : {
			compile.writeln("	mov $0,%%rax")
			initcond(isleft,8,I64,false)
			return null
		}
	}
	
	ret = expr.compile(ctx)
	match type(this.expr) {
		type(BinaryExpr) | type(AssignExpr) : {
			Token t = expr.getType(ctx)
			size = typesize[t]
			initcond(isleft,size,t,false)
			return ret
		}
		type(ast.AddrExpr) : {
			initcond(isleft,8,U64,true)
			return ret
		}
		type(ast.FunCallExpr) : {
			initcond(isleft,8,U64,false)
			return ret
		}
		type(ast.BuiltinFuncExpr) : {
			initcond(isleft,8,U64,false)
			return ret
		}
	}
	
	if ret == null{
		initcond(isleft,8,U64,false)
	}else if type(ret) == type(NewExpr) {
		initcond(isleft,8,U64,false)
	}else if type(ret) == type(ast.VarExpr) 
	{
		v = ret
		if !v.structtype
			initcond(isleft,8,I64,false)
		else
			initcond(isleft,v.size,v.type,v.pointer)
	}else if type(ret) == type(ast.StructMemberExpr) 
	{
		m = ret
		v = m.getMember() 
		initcond(isleft,v.size,v.type,v.pointer)
		
		if type(expr) != type(ast.AddrExpr){
			compile.LoadMember(v)
		}
	}
	else if type(ret) == type(ast.ChainExpr) {
		m = ret
		v = m.ret
		tk = v.type
		if v.isclass tk = ast.U64
		initcond(isleft,v.size,tk,v.pointer)
		
		if type(expr) == type(ast.AddrExpr) {
			
		}else if type(expr) == type(ast.DelRefExpr) {
			compile.LoadSize(v.size,v.isunsigned)
		}else{
			compile.LoadMember(v)
		}
	}else{
		ret.panic("not allowed expression in memory operator:%s\n",ret.toString())
	}
	return ret
}

OperatorHelper::initcond(left,varsize,type,ispointer)
{
	typesize = varsize
	if ispointer typesize = 8
	isunsigned = false
	if type >= ast.U8 && type <= ast.U64 isunsigned = true

	if left {
		ltypesize = typesize
		lvarsize  = varsize
		ltoken    = type
		lisunsigned = isunsigned
		lispointer  = ispointer
		if ispointer ltoken = ast.U64
		return null
	}
	rtypesize = typesize
	rvarsize  = varsize
	rtoken    = type
	risunsigned = isunsigned
	rispointer  = ispointer
	if ispointer rtoken = ast.U64

}