use compiler.gen
use compiler.utils
use std
use os

ChainCall   = 1
MemberCall  = 2
ObjCall     = 3
ClosureCall = 4
FutureCall  = 5

ClassFunc   = 1
AsyncFunc   = 2
StructFunc  = 3
CommonFunc  = 4
ClosureFunc = 5
ExternFunc  = 6

class Function {
    name     = "" // func name
    fntype   = CommonFunc
    st       = null
    cls      = null
    asyncst  = null

    namehid  
    ctxvar    = null
    thisvar   = null

    rettype

    parser   // Parser*
    package  // Package

    locals     = {}  // map{string:VarExpr,}  local variables
    varid      = 0
    params_var = {}  // map{string:VarExpr,} function params
    params_order_var = [] // [VarExpr*,...]  function order params

    //next for asm compute
    is_variadic   = false // function params is variadic
    size    stack   l_stack g_stack ret_stack

    stack_size  // total function stack size

    closures    = [] // [Function*,]
    closureidx 
    receiver    // ClosureExpr* for reciever point
    block       // BlockStmt*
    funcnameid
    mcount = 0
    //async future
    endstates = []
    returns   = []
    iterid    = 0

    fn isasync(){
        return this.fntype == AsyncFunc
    }
    fn argscount(){
        if this.fntype == AsyncFunc
            return 2
        return std.len(this.params_order_var)
    }
}
func incr_closureidx(){
    idx = closureidx
    closureidx += 1
    return idx
}
func incr_labelid(){
    idx = labelidx
    labelidx += 1
    return idx
}

Function::InsertFuncallHead(inits){
	if std.len(inits) <= 0  return true

    exprs = []
	for it : inits {
        call = new gen.FunCallExpr(this.parser.line,this.parser.column)
		call.package = it[0]
		call.funcname = it[1]
		call.is_pkgcall = true
		exprs[] = call
	}

	if this.block == null {
		this.block = new gen.BlockStmt()
	}
	this.block.InsertExpressionsHead(exprs)
}

Function::InsertFuncall(fullpackage,funcname){
    utils.debugf("ast.Function::InsertFuncall() fullpackage:%s funcname:%s",
        fullpackage,funcname
    )
    call = new gen.FunCallExpr(this.parser.line,this.parser.column)

	call.package = fullpackage
	call.funcname = funcname
	call.is_pkgcall = true
	if this.block == null {
		this.block = new gen.BlockStmt()
	}
    //FIXME: if current function return|exit early will cause this init instruct not avaiable
	this.block.stmts[] = call
} 
Function::InsertExpression(expr){
    utils.debug("ast.Function::InsertExpression()")
	if this.block == null {
		this.block = new gen.BlockStmt()
	}
	this.block.stmts[] = expr
} 

//function signature
Function::fullname(){
    funcsig = fmt.sprintf("%s_%s",this.parser.getpkgname(),this.name)
    utils.debugf(
        "ast.Function.fullname(): funcname signature:%s fntype:%d",
        funcsig,this.fntype
    )
    match this.fntype {
        ClassFunc: {
            c = this.cls
        	funcsig = this.parser.getpkgname() + "_" + c.name + "_" + this.name
        }
        StructFunc: {
            c = this.st
        	funcsig = this.parser.getpkgname() + "_" + c.name + "_" + this.name
        }
        AsyncFunc: {
        	funcsig = this.parser.getpkgname() + "_" + this.asyncst.name + "_poll"
        }
    }
    return funcsig
}
Function::getVar(name){
    utils.debugf("ast.Function::getVar() this:%s varname:%s",this.name,name)

    if name == "" return null
    for varname , var : this.params_var {
        if varname == name  
            return var
    }
    if this.locals[name] != null
        return this.locals[name]

    return null
}
Function::beautyName(){
    funcsig = this.parser.getpkgname() + "::" + this.name
    match this.fntype {
        ClassFunc: {
            c = this.cls
        	funcsig = this.parser.getpkgname() + "::" + c.name + "::" + this.name
        }
        StructFunc: {
            c = this.st
        	funcsig = this.parser.getpkgname() + "::" + c.name + "::" + this.name
        }
        AsyncFunc: {
        	funcsig = this.parser.getpkgname() + "::" + this.asyncst.name + "::poll"
        }
    }
    return funcsig
}
Function::getVariadic(){
	for var : this.params_order_var {
    	if var.is_variadic
		    return var
    }
	return null
}

Function::InsertLocalVar(level , var){

    newname = var.varname
    if level >= 0 {
        newname = var.varname + "." + level
        var.varname = newname
    }
	if this.locals[var.varname] != null {
		utils.errorf("something wrong here l:%d top:%d varname:%s fle:%s line %d column %d",
			level,this.parser.ctx.level,
			var.varname,
			this.parser.filename,
			this.parser.line,
			this.parser.column
		)
	}

    var.varid = this.varid
    this.varid += 1
	this.locals[var.varname] = var
}

Function::FindLocalVar(varname){
    return this.getVar(varname)
}

Function::getIterVar(){
    varname = "iter."
	varname += this.iterid

	this.iterid += 1
    iter = new gen.VarExpr(varname,0,0)
	iter.structtype = true
	iter.type = I64
	iter.size = 8
	iter.stack = true
	iter.stacksize = 4
	return iter
}

Function::getMatchcondVar(){
	varname = "mcond."
	varname += this.iterid
	this.iterid += 1

    var = new gen.VarExpr(varname,0,0)
    var.size = 8
    return  var
}