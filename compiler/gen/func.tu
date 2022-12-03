
use ast 
use compile
use internal
use parser
use parser.package
use std
use utils

class ClosureExpr : ast.Ast { 
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
func funcexec(ctx , fc , fce)
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
			std.len(fce.args)
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
		compile.writeln("	 mov %%rax,%d(%%rbp)",compile.currentFunc.stack)
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
    funcname = ""
    package  = ""
    args = [] # [Ast]
	cls       # Class
    is_pkgcall
    is_extern
    is_delref

	tyassert
	func init(line,column){
		super.init(line,column)
	}
}
FunCallExpr::checkFirstThis(ctx,var){
    if(std.len(this.args) == 0){
		this.args[] = var
        return null
    }
    first = this.args[0]
	argsv = [var]

    if(type(first) == type(VarExpr)){
		fe = first
        if(fe.varname != var.varname){
			std.merge(argsv,this.args)
            this.args  = argsv
        }
    }else{
		std.merge(argsv,this.args)
        this.args  = argsv
    }

    return null
}
FunCallExpr::compile(ctx)
{
	this.record()
	utils.debugf("FunCallExpr:  package:%s func:%s",this.package,this.funcname)
	cfunc = compile.currentFunc
	packagename = this.package
	fc = null
	var = null
	if !this.is_pkgcall || this.is_extern {
		packagename      = cfunc.parser.getpkgname()
	}
	if  std.empty(this.funcname) {
		fc = new ast.Function()
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this)

		if std.len(this.args)  > 6 {
			compile.writeln("   add $8,%%rsp")
		}
		return null
	}else if this.cls != null {
        fc = this.cls.getFunc(this.funcname)
        if fc == null
            this.check(false,
                "can not find class func definition of " + this.funcname
			)
        fc.isObj       = false
    }else if this.package != "" && GP().getGlobalVar("",this.package) != null {
        var = GP().getGlobalVar("",this.package)
        goto OBJECT_MEMBER_CALL
    }else if ast.getVar(ctx,this.package) != null {
		var = ast.getVar(ctx,this.package)
		OBJECT_MEMBER_CALL:
		if var.structname != "" && var.structname != null {
			s = package.packages[
				compile.currentParser.import[var.structpkg]
				].getClass(
				var.structname
			)
			if s == null this.panic("static class not exist:" + var.structpkg + "." +  var.structname)
			fn = s.getFunc(this.funcname)
			if(fn == null) this.panic("func not exist")
			this.checkFirstThis(ctx,var)
			funcexec(ctx,fn,this)
			return null
		}else if this.tyassert != null {
			s = package.packages[
					compile.currentParser.import[
						this.tyassert.pkgname
					]
				].getClass(
					this.tyassert.name
			)
			fn = s.getFunc(this.funcname)
			funcexec(ctx,fn,this)
			return null
		}
		this.checkobjcall(var)
		compile.GenAddr(var)
		compile.Load()
		compile.Push()
		internal.object_func_addr(this.funcname)
		compile.Push()
		fc = new ast.Function()
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this)

		if std.len(this.args) > 6 {
			compile.writeln("   add $8,%%rsp")
		}
		return null
	}else if this.package == "" && ast.getVar(ctx,this.funcname) != null {
		var = ast.getVar(ctx,this.funcname)
		compile.GenAddr(var)
		compile.Load()
		compile.Push()
		fc = new ast.Function()
		fc.isExtern    = false
		fc.isObj       = true
		fc.is_variadic = false
		funcexec(ctx,fc,this)
		if std.len(this.args) > 6 {
			compile.writeln("   add $8,%%rsp")
		}
		return null
	}else{
		pkg  = package.packages[packagename]
		if !pkg {
			this.check(false,
				"can not find package definition of" +
				this.package
			)
		}
		fc = pkg.getFunc(this.funcname,this.is_extern)
		if !fc {
			this.check(false,
				fmt.sprintf(
					"can not find func definition of %s : pkgname:%s  this.pkgname:%s ",
					this.funcname,
					packagename,
					this.package
				)
			)
		}
		fc.isObj       = false
	}
	funcexec(ctx,fc,this)
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
FunCallExpr::checkobjcall(var){
    if !this.is_pkgcall {
        if std.len(this.args) == 0 {
            this.panic("funcall expr invalid: should be obj call,but first this arg is null")
        }
        if type(this.args[0]) != type(VarExpr) {
            this.panic("funcall expr invalid: should be obj call,but first this arg should be var")
        }
		This = this.args[0]
        if This.varname != var.varname {
            this.panic("funcall expr invalid: should be obj call,but first this arg should be this")
        }
        return true
    }
    if std.len(this.args) == 0 {
        this.args[] = var
    }else if type(this.args[0]) != type(VarExpr) {
		params = this.args
		this.args = []
        this.args[] = var
		std.merge(this.args,params)
    }else{
		This = this.args[0]
        if This.varname != var.varname {
			params = this.args
			this.args = []
        	this.args[] = var
			std.merge(this.args,params)
        }
    }

}