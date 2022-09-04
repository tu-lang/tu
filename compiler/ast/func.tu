use gen
class Function {
    clsname  = "" # class name
    name    # func name
    isExtern  = false # c ffi ; extern define
    isObj     = false # object call
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
	if this.block == null {
		this.block = new Block()
	}
	this.block.stmts[] = expr
} 

//function signature
Funtion::fullname(){
    funcsig = fmt.sprintf("%s_%s",this.parser.getpkgname(),this.name)
    //class memeber function
    if !std.empty(this.clsname) {
        cls = this.package.getClass(this.clsname)
        if cls == null {
            os.die("class not define :" + this.clsname)
        }
        funcsig = fmt.sprintf("%s_%s_%s",this.parser.getpkgname(),cls.name,this.name)
    }
    return funcsig
}
