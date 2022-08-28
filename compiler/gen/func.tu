
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
	func toString() { return "ClosureExpr(" + this.varname + ")" }
}



ClosureExpr::compile(ctx){
	compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", this.varname)
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
	for arg : args {
		if  type(arg) == type(VarExpr) && cfunc {
			var = arg
			if cfunc.params_var[var.varname] {
				var2  = cfunc.params_var[var.varname]
				if var2 && var2.is_variadic
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
		for (i = 0 ; i < compile.GP_MAX ; i += 1) {
			compile.Pop(compile.args64[gp])
			gp += 1
		}
	if !fc.isObj {
		if fc.isExtern {
			compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
		}else{
			realfuncname = fc.fullname()
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
	this.record()
	utils.debug("FunCallExpr: parsing... package:%s func:%s",this.package,this.funcname)
	cfunc = compile.currentFunc
	packagename = this.package
	fc = null
	if !this.is_pkgcall || this.is_extern {
		packagename      = cfunc.parser.getpkgname()
	}
	if  std.empty(this.funcname) {
		fc = new ast.Function()
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this,packagename)

		if std.len(this.args)  > 6 {
			compile.writeln("   add $8,%%rsp")
		}
		return null
	}else if (var = ast.getVar(ctx,packagename) ) {
		compile.GenAddr(var)
		compile.Load()
		compile.Push()
		internal.object_func_addr(this.funcname)
		compile.Push()
		fc = new ast.Function()
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this,packagename)

		if std.len(this.args) > 6 {
			compile.writeln("   add $8,%%rsp")
		}
		return null
	}else if this.package == null && (var = ast.getVar(ctx,this.funcname)) != null {
		compile.GenAddr(var)
		compile.Load()
		compile.Push()
		fc = new ast.Function()
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
			this.panic(
				"AsmError: can not find package definition of %s" ,
				this.package
			)
		}
		fc = pkg.getFunc(this.funcname,this.is_extern)
		if !fc {
			this.panic(
				"AsmError: can not find func definition of %s %s",
				this.funcname,
				this.package
			)
		}
		fc.isObj       = false
	}
	funcexec(ctx,fc,this,packagename)
	return null
}

FunCallExpr::toString() {
    str = "FunCallExpr[func = "
    str += this.package + "." + this.funcname
    str += ",args = ("
    for arg : this.args {
        str += arg.toString()
        str += ","
    }
    str += ")]"
    return str
}