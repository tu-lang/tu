
use ast 
use compile
use internal
use parser
use parser.package
use std
use utils

class ClosureExpr : Ast { 
	varname = varname
	func init(varname,line,column){
		super.init(line,column)
	}
	func toString() { return "ClosureExpr(" + varname + ")" }
}


class BuiltinFuncExpr : ast.Ast {
    funcname expr from
	func init(line,column){
		super.init(line,column)
	}
}
BuiltinFuncExpr::compile(ctx){
	if funcname == "sizeof" {
		this.check(type(this.expr) == type(VarExpr),"must be varexpr in sizeof()")
		ve = this.expr
		m = package.getStruct(ve.package,ve.varname)
		this.check(m != null,"mem not exist\n")

		compile.writeln("   mov $%d , %%rax",m.size)
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
	}else if  type(ret) == type(VarExpr) {
		if ret.type >= ast.I8 && ret.type <= ast.U64 
			tk = ret.type
	}
	else if type(ret) == type(StructMemberExpr) {
		sm = ret
		m = sm.ret
		if m == null {
			panic("del ref can't find the struct member:%s\n",this.expr.toString())
		}
		if type(this.expr) != type(DelRefExpr) {
			compile.Load(m)
		}
		tk = m.type
	}else if type(ret) == type(ChainExpr) {
		ce = ret
		if ce.ret == null {
			panic("struct chain exp: something wrong here :%s\n",ret.toString())
		}
		compile.Load(ce.ret)
		tk = ce.ret.type
	}

	if funcname == "string" {
		internal.newobject2(String)
		return null
	}else if funcname == "int" {
		//TODO: cast i8 i16 i 32  to  i64
		compile.Cast(tk,ast.I64)
		internal.newobject2(ast.Int)
		return null
	}
}
BuiltinFuncExpr::toString(){
    return "BuiltinFuncExpr:" + funcname +"("+expr.toString() + ")"
}

ClosureExpr::compile(ctx){
	compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", varname)
	return null
}
func funcexec(ctx , fc , fce , package)
{
	args = fce.args
	funcname = fce.funcname
	gp = 0
	fp = 0
	have_variadic = false
	cfunc = compile.currentFunc
	for(arg : args){
		if  type(arg) == type(VarExpr) && cfunc {
			var = arg
			if std.exist(var.varname,cfunc.params_var){
				var2  = res.second
				if(var2 && var2.is_variadic)
					have_variadic = true
			}
		}
	}
	if std.len(fc.params) != std.len(fce.args) 
		utils.debug("ArgumentError: expects %d arguments but got %d\n",
			std.len(fc.params),
			std.len(this.args)
		)

	stack_args = compile.Push_arg(ctx,fc,fce)

	if !cfunc || !cfunc.is_variadic || !have_variadic
		for (i = 0 ; i < GP_MAX ; i += 1) {
			compile.Pop(compile.argreg64[gp])
			gp += 1
		}
	if !fc.isObj {
		if fc.isExtern {
			compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
		}else{
			realfuncname = package + "_" + funcname
			compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", realfuncname)
		}

		compile.writeln("    mov %%rax, %%r10")
		compile.writeln("    mov $%d, %%rax", fp)
		compile.writeln("    call *%%r10")
	}else{
		if std.len(args) > 6 {
			compile.writeln("   mov %d(%%rsp),%r10",(args.size() - 6) * 8)
		}else{
			compile.Pop("%r10")
		}
		compile.writeln("    mov $%d, %%rax", fp)
		compile.writeln("    call *%%r10")
	}


	if compile.currentFunc && compile.currentFunc.is_variadic && have_variadic {
		c = ast.incr_labelid()
		compile.writeln("    mov -8(%%rbp),%%rdi")
		compile.Push()
		internal.call("runtime_get_object_value")
		compile.writeln("	 mov %%rax,%d(%%rbp",compile.currentFunc.stack)
		compile.Pop("%rax")
		if fce.is_delref
			compile.writeln("	add $-6,%d(%%rbp)",compile.currentFunc.stack)
		else
			compile.writeln("	add $-5,%d(%%rbp)",compile.currentFunc.stack)

		compile.writeln("    cmp $0,%d(%%rbp)",compile.currentFunc.stack)
		compile.writeln("    jle L.if.end.%d",c)
		compile.writeln("	 mov %d(%%rbp),%%rdi",compile.currentFunc.stack)
		compile.writeln("	 imul $8,%%rdi")
		compile.writeln("    add %%rdi, %%rsp")
		compile.writeln("L.if.end.%d:",c)
	}else{
		compile.writeln("    add $%d, %%rsp", stack_args * 8)
	}
	return null
}


class FunCallExpr : ast.Ast {
    funcname
    package
    args = [] # [Ast]
    is_pkgcall
    is_extern
    is_delref
	func init(line,column){
		super.init(line,column)
	}
}
FunCallExpr::compile(ctx)
{
	record()
	utils.debug("FunCallExpr: parsing... package:%s func:%s",package,funcname)
	cfunc = compile.currentFunc
	packagename = this.package
	fc = null
	if !is_pkgcall || is_extern {
		packagename      = cfunc.parser.getpkgname()
	}
	if  std.empty(funcname) {
		fc = new Function()
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this,packagename)

		if std.len(this.args)  > 6 {
			compile.writeln("   add $8,%%rsp")
		}
		return null
	}else if ast.getVar(ctx,packagename) != null  {
		compile.GenAddr(var)
		compile.Load()
		compile.Push()
		internal.object_func_addr(funcname)
		compile.Push()
		fc = new Function()
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this,packagename)

		if std.len(this.args) > 6 {
			compile.writeln("   add $8,%%rsp")
		}
		return null
	}else if ast.getVar(ctx.funcname) != null {
		compile.GenAddr(var)
		compile.Load()
		compile.Push()
		fc = new Function()
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this,packagename)
		if std.len(this.args) > 6 {
			compile.writeln("   add $8,%%rsp")
		}
		return null
	}else{
		pkg  = package.packages[packagename]
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
	funcexec(ctx,fc,this,packagename)
	return null
}

FunCallExpr::toString() {
    str = "FunCallExpr[func = "
    str += package + "." + funcname
    str += ",args = ("
    for (arg : args) {
        str += arg.toString()
        str += ","
    }
    str += ")]"
    return str
}