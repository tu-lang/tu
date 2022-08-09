class Function {
    clsname # class name
    name    # func name
    isExtern # c ffi ; extern define
    isObj    # object call
    structname
    rettype

    parser   # Parser*
    package  # Package

    locals   # map{string:VarExpr,}  local variables
    params_var # map{string:VarExpr,} function params
    params_order_var # [VarExpr*,...]  function order params

    //next for asm compute
    is_variadic  # function params is variadic
    size    stack   l_stack g_stack

    stack_size  # total function stack size

    closures    # [Function*,]
    closureidx 

    receiver    # ClosureExpr* for reciever point

    params      # [string...]
    block       # Block*
    retExpr     # Expression*

    func init(){
        clsname = ""
        isExtern = false
        isObj = false
        parser = null
        package = null
        is_variadic = false

        locals = {}
        params_var = {}
        params_order_var = []
        closure = []
        params  = []
    }

}
# auto increment closure id
closureidx

# auto increment count
compileridx

func incr_closureidx(){
    idx = closureidx
    closureidx += 1
    return idx
}
func incr_compileridx(){
    idx = compileridx
    compileridx += 1
    return idx
}