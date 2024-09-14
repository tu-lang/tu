
use compiler.ast 
use compiler.compile
use compiler.internal
use compiler.parser
use compiler.parser.package
use std
use compiler.utils

class ClosureExpr : ast.Ast { 
	varname = varname
	def
	func init(varname,line,column){
		super.init(line,column)
	}
	func toString() { return "ClosureExpr(" + this.varname + ")" }
}

ClosureExpr::compile(ctx,load){
	compile.writeln("    lea %s(%%rip), %%rax", this.varname)
	internal.newfuncobject(
		std.len(this.def.params_order_var),
		this.def.is_variadic,
		this.def.mcount
	)
	return null
}

class FunCallExpr : ast.Ast {
    funcname = ""
    package  = ""
    args = [] // [Ast]
	cls       // Class
    is_pkgcall
    is_extern
    is_delref

	is_dyn = false
	fcs    = null
	tyassert
	p  	   = null 
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
FunCallExpr::compile(ctx,load)
{
	this.record()
	utils.debugf("FunCallExpr:  package:%s func:%s free:%d",this.package,this.funcname,load)
	cfunc = compile.currentFunc
	packagename = this.package
	fc = null
	var = null
	if !this.is_pkgcall || this.is_extern {
		packagename      = cfunc.parser.getpkgname()
	}
	if  std.empty(this.funcname) {
		this.check(false,"funcname is empty")
	} 
	
	if this.cls != null {
        fc = this.cls.getFunc(this.funcname)
    }else if this.package != "" && GP().getGlobalVar("",this.package) != null {
        var = GP().getGlobalVar("",this.package)
        goto OBJECT_MEMBER_CALL
    }else if ctx.getLocalVar(this.package) != null {
		var = ctx.getLocalVar(this.package)
		OBJECT_MEMBER_CALL:
		if var.structname != "" && var.structname != null {
			s = compile.currentParser.pkg.getPackage(var.structpkg)
				.getClass(var.structname)
			if s == null this.panic("static class not exist:" + var.structpkg + "." +  var.structname)
			fc = s.getFunc(this.funcname)
			if(fc == null) this.panic("func not exist")
			this.checkFirstThis(ctx,var)
			this.call(ctx,fc,load)
			return this
		}else if this.tyassert != null {
			s = compile.currentParser.pkg
					.getPackage(this.tyassert.pkgname)
					.getClass(this.tyassert.name)
			fc = s.getFunc(this.funcname)
			this.checkFirstThis(ctx,var)
			this.call(ctx,fc,load)
			return this
		}
		this.checkobjcall(var)
		return this.compile2(ctx,load,ast.ObjCall,var)
	}else if this.package == "" && ctx.getLocalVar(this.funcname) != null {
		var = ctx.getLocalVar(this.funcname)

		if var.structtype {
			return this.closcall(ctx,var,load)
		}
		return this.compile2(ctx,load,ast.ClosureCall,var)
	}else{
		pkg  = package.packages[packagename]
		if !pkg {
			this.check(false,
				"can not find package definition of" +
				this.package
			)
		}
		fc = pkg.getFunc(this.funcname,this.is_extern)
	}

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
	this.call(ctx,fc,load)
	return this
}

FunCallExpr::compile2(ctx, load, ty, obj){
	cfunc = compile.currentFunc
	match ty {
    	ast.ChainCall: {
            internal.get_func_value()
    	}
    	ast.MemberCall: {
			internal.object_func_addr2(this,this.funcname)
    	}
    	ast.ObjCall: {
			compile.GenAddr(obj)
        	compile.Load()
        	compile.Push()

			internal.object_func_addr2(this,this.funcname)
		}
    	ast.ClosureCall: {
			compile.GenAddr(obj)
        	compile.Load()
			internal.get_func_value()
		}
    	_: this.check(false,"unknown dyn compile")
    }

	vlid = ast.incr_labelid()
	mretnull_label   = cfunc.fullname() + "_mrnull_" + vlid
	mretdone_label   = cfunc.fullname() + "_mrdone_" + vlid

    compile.writeln("    cmp $1 , 32(%%rax)")
    compile.writeln("    jle %s",mretnull_label)
	compile.writeln("	 sub 40(%%rax) , %%rsp")
    compile.writeln("    mov %%rsp , %%rdi")
    compile.Push()
    compile.writeln("    push %%rdi")
    compile.writeln("    jmp %s",mretdone_label)
    //else
    compile.writeln("%s:",mretnull_label)
    compile.Push()
	compile.Push()
    //done
    compile.writeln("%s:",mretdone_label)

    if this.hasVariadic() {
        this.dynstackcall2(ctx,load)
    }else{
        this.dynstackcall(ctx,load)
    }

	this.is_dyn = true
	return this
}

FunCallExpr::freeret(){
	fc = this.fcs
    if fc.mcount == 0 return null

    stack = fc.mcount
    stack *= 8
    compile.writeln("    add $%d , %%rsp",stack)
}

FunCallExpr::dynfreeret(){
	cfunc = compile.currentFunc
	vlid = ast.incr_labelid()
	freenull_label   = cfunc.fullname() + "_freenull_" + vlid
	freedone_label   = cfunc.fullname() + "_freedone_" + vlid
    //sub 40(%rax) , %rsp 
    //push typeinfo  
    compile.Pop("%rdi")
    compile.Pop("%rdi")
    compile.writeln("    cmp $1 , 32(%%rdi)")
    compile.writeln("    jle %s",freenull_label)
	compile.writeln("	   add 40(%%rdi) , %%rsp")
    compile.writeln("%s:",freenull_label)
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

FunCallExpr::getStruct(){
	s = this.p.getStruct(this.package,this.funcname)
	if s == null {
		this.check(false,"await function not found")
	}
	return s
}

FunCallExpr::gennewawait(){
	s = this.getStruct()

	newsvar = new NewStructExpr(0,0)
	newsvar.init = new StructInitExpr(0,0)
	newsvar.init.pkgname = s.pkg
    newsvar.init.name = s.name
    return newsvar
}