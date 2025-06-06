
use compiler.ast 
use compiler.compile
use compiler.internal
use compiler.parser
use compiler.parser.package
use std
use compiler.utils

defaultfunc = new ast.Function()

class ClosureExpr : ast.Ast { 
	varname = varname
	def
	func init(varname,line,column){
		super.init(line,column)
	}
	func toString() { return "ClosureExpr(" + this.varname + ")" }
}

ClosureExpr::compile(ctx,load){
	cf = this.def
	stack = 1
    if cf.parent != null && std.len(cf.caporders) != 0 {
        
        for i = std.len(cf.caporders) - 1; i >= 0; i -= 1 {
			arg = cf.caporders[i]
			if arg.stack {
				this.check(false," stack var can't capture :" + arg.varname)
			}
			ret = arg.compile(ctx,true)
            stack += 1
            if ret != null {
				ty<i32> = ret.getType(ctx)
                if ast.isfloattk(ty) 
                    compile.Pushf(ty)
                else
                    compile.Push()
            }else   compile.Push() 
        }
    }
    compile.writeln("    push $%d",std.len(cf.caporders))

	// compile.writeln("    lea %s(%%rip), %%rax", this.varname)
	internal.newfuncobject(
		std.len(this.def.params_order_var),
		this.def.is_variadic,
		this.def.mcount,
		true,
		this.varname
	)
    compile.writeln("    add $%d , %%rsp",stack * 8)

	return null
}

class FunCallExpr : ast.Ast {
    funcname = ""
    package  = ""
    args = [] // [Ast]
	st	 = null   	  // Struct
	cls  = null       // Class
	asyncgen = false
    is_pkgcall
    is_extern
    is_delref

	is_dyn = false
	fcs    = null
	p  	   = null 

	gen    = false
	dt
	var    = null
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
FunCallExpr::geninit(ctx)
{
	if this.gen return null
	this.gen = true

	utils.debugf("FunCallExpr::geninit:  package:%s func:%s",this.package,this.funcname)
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
	if this.st != null {
		fc = this.st.getFunc(this.funcname)
	}else if this.cls != null {
        fc = this.cls.getFunc(this.funcname)
    }else if this.package != "" && GP().getGlobalVar("",this.package) != null {
        var = GP().getGlobalVar("",this.package)
        goto OBJECT_MEMBER_CALL
    }else if ctx.getLocalVar(this.package) != null {
		var = ctx.getLocalVar(this.package)
		OBJECT_MEMBER_CALL:
		if var.structname == "Future" && this.funcname == "poll" {
			if var.structpkg == "runtime" {
				this.fcs = defaultfunc
				this.var = var
				this.dt  = ast.FutureCall
				return this
			}	
			if var.structpkg == "" && GP().getpkgname() == "runtime" {
				this.fcs = defaultfunc
				this.var = var
				this.dt  = ast.FutureCall
				return this
			}
		}
		if var.structtype && var.structname != "" && var.structname != null {
			s = compile.currentParser.pkg.getPackage(var.structpkg)
				.getStruct(var.structname)
			if s == null this.panic("static class not exist:" + var.structpkg + "." +  var.structname)
			fc = s.getFunc(this.funcname)
			if(fc == null) 
				this.check(false,"func not exist in funccall expr compile")
			this.checkFirstThis(ctx,var)
			this.dt = ast.StaticCall
			this.fcs = fc
			return this
		}else if this.tyassert != null {
			s = compile.currentParser.pkg
					.getPackage(this.tyassert.pkg)
					.getStruct(this.tyassert.name)
			fc = s.getFunc(this.funcname)
			this.checkFirstThis(ctx,var)
			this.dt = ast.StaticCall
			this.fcs = fc
			return this
		}
		this.dt = ast.ObjCall
		this.var = var
		this.fcs = defaultfunc
		return null
	}else if this.package == "" && ctx.getLocalVar(this.funcname) != null {
		var = ctx.getLocalVar(this.funcname)
		this.var = var
		this.fcs = defaultfunc
		if var.structtype {
			this.fcs = getGLobalFunc(
				var.structpkg,
				var.structname
			)
			this.dt = ast.ClosureCall2
			return null
		}
		this.dt = ast.ClosureCall
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

	this.dt = ast.StaticCall
	this.fcs = fc
	return this
}

FunCallExpr::compile(ctx , load){
	this.record()
	utils.debugf("FunCallExpr:  package:%s func:%s free:%d",this.package,this.funcname,load)

	this.geninit(ctx)
	cfunc = compile.currentFunc

	match this.dt {
		ast.ClosureCall : this.compile2(ctx,load,ast.ClosureCall,this.var)
		ast.ClosureCall2: this.closcall(ctx,this.var,load)
		ast.ObjCall:	  this.compile2(ctx,load,ast.ObjCall,this.var)
		ast.FutureCall:	  this.compile2(ctx,load,ast.FutureCall,this.var)
		ast.StaticCall:	  this.call(ctx,this.fcs,load)

		_: {
			this.check(false,"compile unknown funcall type")
		}
	}
	return this
}

FunCallExpr::compile2(ctx, load, ty, obj){
	this.gen = true
	cfunc = compile.currentFunc
	match ty {
    	ast.ChainCall: {
			this.fcs = defaultfunc
            internal.get_func_value()
			ty = ast.ClosureCall
    	}
    	ast.MemberCall: {
			this.fcs = defaultfunc
			internal.object_func_addr2(this,this.funcname)
    	}
    	ast.ObjCall: {
			this.fcs = defaultfunc
			compile.GenAddr(obj)
        	compile.Load()
        	compile.Push()

			internal.object_func_addr2(this,this.funcname)
		}
    	ast.ClosureCall: {
			this.fcs = defaultfunc
			compile.GenAddr(obj)
        	compile.Load()
			internal.get_func_value()
		}
		ast.FutureCall: {
			s = package.getStruct("runtime","Future")
			this.check(s != null,"Future::poll() not found")
			this.fcs = s.getFunc("poll")
			this.check(this.fcs != null," Future::poll() not found")
			compile.GenAddr(obj)
			compile.Load()
			internal.get_future_poll()
		}
    	_: this.check(false,"unknown dyn compile")
    }

	if ty == ast.ClosureCall {
		this.handleclosure()
	}

	vlid = ast.incr_labelid()
	mretnull_label   = cfunc.fullname() + "_mrnull_" + vlid
	mretdone_label   = cfunc.fullname() + "_mrdone_" + vlid

	//rfc100-4:
	if ty != ast.FutureCall {
        compile.writeln(
            "   cmp $0, 52(%%rax)\n" +
            "   jg  %s",
            mretnull_label
        )
    }

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
        this.dynstackcall(ctx,ty,load)
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
		this.check(false,"await function not found in no async env")
	}
	return s
}

FunCallExpr::getFutureStruct(){
	p = this.p
    fc = this
	curf = ast.GF()
    if !this.asyncgen && fc.package != "" && fc.package != null {
		var = ast.GP().getGlobalVar("",fc.package)
        if  var == null {
            var = curf.FindLocalVar(fc.package)
        }
        if var != null {
            if !var.structtype || var.structname == "" {
                this.check(false,"await function only support for struct member")
            }
			s = p.pkg.getPackage(var.structpkg).getStruct(var.structname)
            if s == null this.check(false,"gen await static class not exist:" + var.structpkg + "." +  var.structname)
			asyncfn = s.getFunc(fc.funcname)
            if(asyncfn == null || asyncfn.fntype != ast.AsyncFunc){
                this.check(false,"gen await: func not async ")
            }
            return asyncfn.asyncst
        }
    }

	s = this.p.getStruct(this.package,this.funcname)
    if s == null {
        this.check(false,"await function not found when genawait")
    }
    return s
}

FunCallExpr::gennewawait(){
	s = this.getFutureStruct()
	if s == null {
		this.check(false,"await function not found when gen await")
	}

	newsvar = new NewStructExpr(0,0)
	newsvar.init = new StructInitExpr(0,0)
	newsvar.init.pkgname = s.pkg
    newsvar.init.name = s.name

	for i = 1 ; i < std.len(s.member) ; i += 1 {
		m = s.member[i]
		if i <= std.len(this.args) {
			newsvar.init.fields[m.name] = this.args[i - 1]
		}else {
			newsvar.init.fields[m.name] = new gen.NullExpr(0,0)
		}
	}

    return newsvar
}

FunCallExpr::handleclosure() {
	params = this.args
	pos = new ClosPosExpr(std.len(params) + 1,this.line,this.column)
	//find params count
	this.args = []

	this.args[] = pos
	std.merge(this.args,params)
}