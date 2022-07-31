
use ast 
use compile
use internal
use parser
use std
use utils

LabelExpr::compile(ctx){
	record()
	this.obj.writeln("%s:",label)
	return this
}

BuiltinFuncExpr::compile(ctx){
	if funcname == "sizeof" {
		this.check(type(*this.expr) == type(VarExpr),"must be varexpr in sizeof()")
		ve = this.expr
		mem = Package::getStruct(ve.package,ve.varname)
		this.check(mem != null,"mem not exist\n")

		this.obj.writeln("   mov $%d , %%rax",mem.size)
		return null
	}
	//2. 如果是值类型
	check(type(*expr) != type(IntExpr))
	check(type(*expr) != type(StringExpr))
	check(type(*expr) != type(ArrayExpr))
	check(type(*expr) != type(MapExpr))
	check(type(*expr) != type(NullExpr))
	check(type(*expr) != type(CharExpr))
	check(type(*expr) != type(DoubleExpr))



	//2. 其他内置函数则需要计算
	// %rax
	ret = this.expr.compile(ctx)

	//获取到 数据类型
	Token tk = ast.I64
	if (ret == null){
	}
	else if  type(ret) == type(VarExpr) {
		if ret.type >= ast.I8 && ret.type <= ast.U64 
			tk = ret.type
	}
	else if type(*ret) == type(ast.StructMemberExpr) {
		sm = ret
		Member* m = sm.ret
		if m == null {
			parse_err("del ref can't find the struct member:%s\n",this.expr.toString())
		}
		if type(this.expr) != type(as.tDelRefExpr) {
			this.obj.Load(m)
		}
		tk = m.type
	}else if type(ret) == type(ast.ChainExpr) {
		ce = ret
		if ce.ret == null {
			this.parse_err("struct chain exp: something wrong here :%s\n",ret.toString())
		}
		this.obj.Load(ce.ret)
		tk = ce.ret.type
	}

	if funcname == "string" {
		internal.newobject2(String)
		return null
	}else if funcname == "int" {
		//TODO: cast i8 i16 i 32  to  i64
		this.obj.Cast(tk,ast.I64)
		internal.newobject2(ast.Int)
		return null
	}
}

ClosureExpr::compile(ctx){
	this.obj.writeln("    mov %s@GOTPCREL(%%rip), %%rax", varname)
	return null
}
func funcexec(ctx , fc , fce , package)
{
	args = fce.args
	funcname = fce.funcname
	gp = 0
	fp = 0
	have_variadic = false
	cfunc = this.obj.currentFunc
	for(arg : args){
		if  type(arg) == type(ast.VarExpr) && cfunc {
			var = arg
			if std.exist(cfunc.params_var,var.varname){
				VarExpr* var2  = res.second
				if(var2 && var2.is_variadic)
					have_variadic = true
			}
		}
	}
	if std.len(fc.params) != std.len(fce.args) 
		utils.debug("ArgumentError: expects %d arguments but got %d\n",std.len(func.params),std.len(this.args)

	stack_args = this.obj.Push_arg(ctx,fc,fce)

	if !cfunc || !cfunc.is_variadic || !have_variadic
		for (int i = 0 ; i < GP_MAX ; i += 1) {
			this.obj.Pop(this.obj.argreg64[gp])
			gp += 1
		}
	if !fc.isObj {
		if func.isExtern {
			this.obj.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
		}else{
			realfuncname = package + "_" + funcname
			this.obj.writeln("    mov %s@GOTPCREL(%%rip), %%rax", realfuncname)
		}

		this.obj.writeln("    mov %%rax, %%r10")
		this.obj.writeln("    mov $%d, %%rax", fp)
		this.obj.writeln("    call *%%r10")
	}else{
		if std.len(args) > 6 {
			this.obj.writeln("   mov %d(%%rsp),%r10",(args.size() - 6) * 8)
		}else{
			this.obj.Pop("%r10")
		}
		this.obj.writeln("    mov $%d, %%rax", fp)
		this.obj.writeln("    call *%%r10")
	}


	if this.obj.currentFunc && this.obj.currentFunc.is_variadic && have_variadic {
		c = this.obj.incr_count()
		this.obj.writeln("    mov -8(%%rbp),%%rdi")
		this.obj.writeln("    mov %%rdi,%d(%%rbp)",this.obj.currentFunc.stack)
		this.obj.writeln("    sub $-7,%d(%%rbp)",this.obj.currentFunc.stack)
		this.obj.writeln("    cmp $0,%d(%%rbp)",this.obj.currentFunc.stack)
		this.obj.writeln("    jle L.if.end.%d",c)
		this.obj.writeln("    cmp %d(%%rbp),%%rdi",this.obj.currentFunc.stack)
		this.obj.writeln("    add %%rdi, %%rsp", stack_args * 8)
		this.obj.writeln("L.if.end.%d:",c)
	}else{
		this.obj.writeln("    add $%d, %%rsp", stack_args * 8)
	}
	return null
}

FunCallExpr::compile(std::ctx)
{
	record()
	utils.debug("FunCallExpr: parsing... package:%s func:%s",package,funcname)
	cfunc = this.obj.currentFunc
	package = this.package
	fc = null
	if !is_pkgcall || is_extern {
		package      = cfunc.parser.getpkgname()
	}
	if  funcname.empty() {
		fc = new Function
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this,package)

		if std.len(this.args)  > 6 {
			this.obj.writeln("   add $8,%%rsp")
		}
		return null
	}else if ast.getVar(ctx,package) != null  {
		this.obj.GenAddr(var)
		this.obj.Load()
		this.obj.Push()
		internal.object_func_addr(funcname)
		this.obj.Push()
		fc = new Function()
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this,package)

		if std.len(this.args) > 6 {
			this.obj.writeln("   add $8,%%rsp")
		}
		return null
	}else if ast.getVar(ctx.funcname) != null {
		this.obj.GenAddr(var)
		this.obj.Load()
		this.obj.Push()
		fc = new Function()
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this,package)
		if std.len(this.args) > 6 {
			this.obj.writeln("   add $8,%%rsp")
		}
		return null
	}else{
		pkg  = parser.packages[package]
		if !pkg {
			check(false,
					"AsmError: can not find package definition of " + package)
		}
		fc = pkg.getFunc(funcname,is_extern)
		if !fc check(false,
					"AsmError: can not find func definition of " + funcname)
		fc.isObj       = false
		if fc == null
			check(false,
					"AsmError: can not find function definition of " + package)
	}
	funcexec(ctx,fc,this,package)
	return null
}