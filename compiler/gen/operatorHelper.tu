OperatorHelper::init(ctx,lhs,rhs,Token opt) {
	this.ctx = ctx
	this.lhs = lhs
	this.rhs = rhs
	this.opt = opt
	this.ltypesize = 8
	this.lvarsize = 1
	this.ltoken = ast.I8
	this.lisunsigned = false
	this.lispointer = false
	this.needassign = false
	this.lmember = null
	this.ax = "%rax"
	this.di = "%rdi"
	this.dx = "%rdx"
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
			if lmember compile.Load(lmember)
			else        compile.Load(ltypesize,lisunsigned)
			compile.Push()
		}
	} else {
		genRight(true,lhs)
		compile.Push()
	}
	
	if this.rhs genRight(false,rhs) 
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
		compile.writeln("   and $%I, %%rdi", (1L << lmember.bitwidth) - 1)
		compile.writeln("	shl $%d, %%rdi", lmember.bitoffset)
		compile.writeln("   mov (%%rsp), %%rax")
		compile.Load(lmember.size,lmember.isunsigned)
		//FIXME: 
		//mask = ((1L << lmember.bitwidth) - 1) << lmember.bitoffset
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
	if !this.rhs{
		compile.Pop("%rax")
		match opt {
			LOGNOT: {
				compile.CreateCmp(ltypesize)
				compile.writeln("	sete %%al")
				compile.writeln("	movzx %%al, %%rax")
				return null
			}
			BITNOT: {
				compile.writeln("	not %%rax")
				return null
			}
			_ :	parse_err("asmgen: must !,~ at unary expression,not %s\n",getTokenString(opt))
		}
	}
	Token base = max(rtoken,ltoken)
	tke = "token_max(lhs,rhs) should in(i8,u64)"
	tke += " ltoken:" + std::ltoken + " rtoken:" + std::rtoken
	tke += "\n"
	tke += lhs.toString() + "\n"
	tke += rhs.toString() + "\n"
	this.lhs.check(base >= ast.I8 && base <= ast.U64,tke)
	
	if opt == ASSIGN return null
	
	compile.Cast(rtoken,base)
	compile.writeln("	mov %%rax,%%rdi")
	compile.Pop("%rax")
	compile.Cast(ltoken,base)
	
	match opt{
		ADD_ASSIGN | ADD:	compile.writeln("	add %s, %s", di, ax)
		SUB_ASSIGN | SUB:	compile.writeln("	sub %s,%s",di,ax)
		MUL_ASSIGN | ast.MUL:	compile.writeln("	imul %s,%s",di,ax)
		BITAND | BITAND_ASSIGN:	compile.writeln("	and %s,%s",di,ax)
		BITOR  | BITOR_ASSIGN:	compile.writeln("	or %s,%s",di,ax)

		DIV_ASSIGN | DIV | MOD_ASSIGN | MOD : {
			if lisunsigned
			{
				compile.writeln("	mov $0,%s",dx)
				compile.writeln("	div %s",di)
			}else{
				if ltypesize == 8	compile.writeln("	cqo")
				else				compile.writeln("	cdq")
				compile.writeln("	idiv %s",di)
			}
			if opt == MOD_ASSIGN || opt == MOD
      			compile.writeln("	mov %%rdx, %%rax")
		}
		EQ | NE | LE | LT | GE | GT: {
			cmp = "sete"
			match opt {
				EQ : cmp = "sete"
				NE : cmp = "setne"
				LE : {
					if lisunsigned cmp = "setbe"
					else            cmp = "setle"
				}
				LT : {
					if lisunsigned cmp = "setb"
					else			cmp = "setl"
				}
				GE : cmp = "setge"
				GT : cmp = "setg"
			}
			
			compile.writeln("	cmp %s,%s",di,ax)
			compile.writeln("	%s %%al",cmp)
			compile.writeln("	movzb %%al, %%rax")
		}
		SHL_ASSIGN | SHL : {
    		compile.writeln("	mov %%rdi, %%rcx")
    		compile.writeln("	shl %%cl, %s", ax)
		}
		SHR_ASSIGN | SHR : {
    		compile.writeln("	mov %%rdi, %%rcx")
			if lisunsigned	compile.writeln("	shr %%cl, %s", ax)
    		else			compile.writeln("	sar %%cl, %s", ax)
		}
		LOGOR : { 
			c = ast.incr_compileridx()
			
			if ltypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	jne .L.true.%d", c)
			
			compile.writeln("	mov %%rdi,%%rax")
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
		LOGAND : { 
			c = ast.incr_compileridx()
			
			if ltypesize <= 4	compile.writeln("	cmp $0,%%eax")
			else				compile.writeln("	cmp $0,%%rax")
			compile.writeln("	je .L.false.%d", c)
			
			compile.writeln("	mov %%rdi,%%rax")
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

			if type(ret) == type(ChainExpr) {
				ce = ret
				m = ce.ret
				if m.pointer compile.Load()
				lmember = m
				tk = m.type
				if m.isclass tk = ast.U64
				initcond(true,m.pointer ? 8 : m.size,m.size,tk,m.isunsigned,m.pointer)
				return ce
			}

			if ret == null || type(ret) != type(VarExpr) 
				parse_err("not VarExpr,only support *(class var) = expression :%s %d\n",lhs.toString(),lhs.line)
			rv = ret
			if !rv.structtype
				parse_err("not structtype,only support *(class var) = expression :%s\n",lhs.toString())
			
			initcond(true,rv.pointer ? 8 : rv.size,rv.size,rv.type,rv.isunsigned,rv.pointer)
			return rv
		}
		type(ast.ChainExpr) : {
			ce = lhs
			ce.compile(ctx)
			m = ce.ret
			lmember = m
			
			tk = m.type
			if m.isclass tk = ast.U64
			initcond(true,m.pointer ? 8 : m.size,m.size,tk,m.isunsigned,m.pointer)
			return ce
		}
		type(ast.StructMemberExpr) : {
			smember = lhs
			smember.compile(ctx)
			m = smember.getMember()
			lmember = m
			initcond(true,m.pointer ? 8 : m.size,m.size,m.type,m.isunsigned,m.pointer)
			return smember
		}
		type(VarExpr) : {
			if !var.structtype
				parse_err("genLeft: lhs not structExpr %s \n",lhs.toString())
			
			initcond(true,var.pointer ? 8 : var.size,var.size,var.type,var.isunsigned,var.pointer)
			
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
			ie = expr;	
			compile.writeln("	mov $%s,%%rax",ie.literal)
			initcond(isleft,8,8,I64,false,false)
			return ie
		}
		type(StringExpr): {
			ie = expr;
			writeln("	lea %s(%%rip), %%rax",ie.name)
			initcond(isleft,8,8,U64,true,true);
			return ie
		}
		type(NullExpr) : {
			compile.writeln("	mov $0,%%rax")
			initcond(isleft,8,8,I64,false,false)
			return null
		}
	}
	
	ret = expr.compile(ctx)
	match type(this.expr) {
		type(BinaryExpr) | type(AssignExpr) : {
			Token t = expr.getType(ctx)
			size = typesize[t]
			iu = false
			if t == ast.U8 || t == ast.U16 || t == ast.U32 || t == ast.U64
				iu = true
			initcond(isleft,size,size,t,iu,false)
			return ret
		}
		type(ast.AddrExpr) : {
			initcond(isleft,8,8,U64,true,true)
			return ret
		}
		type(FunCallExpr) : {
			initcond(isleft,8,8,U64,true,false)
			return ret
		}
		type(BuiltinFuncExpr) : {
			initcond(isleft,8,8,U64,true,false)
			return ret
		}
	}
	
	if ret == null{
		initcond(isleft,8,8,U64,true,false)
		
	}else if type(ret) == type(NewExpr) {
		initcond(isleft,8,8,U64,true,false)
	}else if type(ret) == type(VarExpr) 
	{
		v = ret
		if !v.structtype
			initcond(isleft,8,8,I64,false,false)
		else
			initcond(isleft,v.pointer ? 8 : v.size,v.size,v.type,v.isunsigned,v.pointer)
	}else if type(ret) == type(ast.StructMemberExpr) 
	{
		m = ret
		v = m.getMember(); 
		initcond(isleft,v.pointer ? 8 : v.size,v.size,v.type,v.isunsigned,v.pointer)
		
		if type(expr) != type(ast.AddrExpr){
			compile.Load(v)
		}
	}
	else if type(ret) == type(ChainExpr) {
		m = ret
		v = m.ret
		tk = v.type
		if v.isclass tk = ast.U64
		initcond(isleft,v.pointer ? 8 : v.size,v.size,tk,v.isunsigned,v.pointer)
		
		if type(expr) == type(ast.AddrExpr) {
			
		}else if type(expr) == type(ast.DelRefExpr) {
			compile.Load(v.size,v.isunsigned)
		}else{
			compile.Load(v)
		}
	}else{
		parse_err("not allowed expression in memory operator:%s\n",ret.toString())
	}
	return ret
}

OperatorHelper::initcond(left,typesize,varsize,Token type,isunsigned,ispointer)
{
	if left{
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