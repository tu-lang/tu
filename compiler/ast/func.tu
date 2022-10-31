use gen
use utils
use std
use os

class Function {
    clsname  = "" # class name
    name    # func name
    isExtern  = false # c ffi ; extern define
    isObj     = false # object call
    isMem     = false # static class function
    structname
    rettype

    parser   # Parser*
    package  # Package

    locals     = {}  # map{string:VarExpr,}  local variables
    params_var = {}  # map{string:VarExpr,} function params
    params_order_var = [] # [VarExpr*,...]  function order params

    //next for asm compute
    is_variadic   = false # function params is variadic
    size    stack   l_stack g_stack

    stack_size  # total function stack size

    closures    = [] # [Function*,]
    closureidx 

    receiver    # ClosureExpr* for reciever point

    params      = [] # [string...]
    block       # Block*
    retExpr     # Expression*

    funcnameid
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
Function::InsertFuncall(fullpackage,funcname){
    utils.debugf("ast.Function::InsertFuncall() fullpackage:%s funcname:%s",
        fullpackage,funcname
    )
    call = new gen.FunCallExpr(this.parser.line,this.parser.column)

	call.package = fullpackage
	call.funcname = funcname
	call.is_pkgcall = true
	if this.block == null {
		this.block = new Block()
	}
	this.block.stmts[] = call
} 
Function::InsertExpression(expr){
    utils.debug("ast.Function::InsertExpression()")
	if this.block == null {
		this.block = new Block()
	}
	this.block.stmts[] = expr
} 

//function signature
Function::fullname(){
    funcsig = fmt.sprintf("%s_%s",this.parser.getpkgname(),this.name)
    utils.debugf(
        "ast.Function.fullname(): funcname signature:%s clsname:%s",
        funcsig,this.clsname
    )
    //class memeber function
    if !std.empty(this.clsname) {
        if !this.isMem {
        	c = this.package.getClass(this.clsname)
        	if c == null || !c.found {
                os.die("class not define :" + this.clsname)
        	}
        	funcsig = this.parser.getpkgname() + "_" + c.name + "_" + this.name
		}else{
            c = this.package.getStruct(this.clsname)
        	funcsig = this.parser.getpkgname() + "_" + c.name + "_" + this.name
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

    for varname , var : this.locals {
        if varname == name
            return var
    }
    return null
}
Function::beautyName(){
    funcname = this.parser.getpkgname() + "::" + this.name
	if this.clsName != "" {
        c = this.package.getClass(this.clsname)
        if c == null {
            os.die("fn exception class not exist:" + this.clsname)
        }
        funcname = this.parser.getpkgname() + "::" + c.name + "::" + this.name
    }
	return funcname
}
Function::getVariadic(){
	for var : this.params_order_var {
    	if var.is_variadic
		    return var
    }
	return null
}