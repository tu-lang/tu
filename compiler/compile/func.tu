Compiler::registerFunc(fn)
{
    if std.len(fn.closures)
    {
        for(closure : fn.closures){
            funcname = "func_" + ast.incr_closureidx()
            closure.receiver.varname = fn.parser.getpkgname() + "_" + funcname
            closure.parser = fn.parser
            closure.name   = funcname
            registerFunc(closure)
        }
    }
    currentFunc = fn
    CreateFunction(fn)
    currentFunc = null
}
Compiler::registerFuncs()
{
    utils.debug("register functions")
    sign = 0
    for(p :parser.funcs){
        registerFunc(p.second)
    }
}
Compiler::CreateFunction(fn,Class* c)
{
    if fn.clsName != "" {
        c = fn.parser.pkg.getClass(fn.clsName)
        if (c == null) {
            os.die("fn exception")
        }
    }
    if fn.isExtern return
    if fn.block == null return
    funcname = fn.parser.getpkgname() + "_" + fn.name
    
    if c {
        funcname = fn.parser.getpkgname() + "_" + c.name + "_" + fn.name
    }
    utils.debug("create function :%s",funcname)
    
    writeln(".global %s", funcname)
    writeln("%s:", funcname)
    writeln("    push %%rbp")
    writeln("    mov %%rsp, %%rbp")
    writeln("    sub $%d, %%rsp", fn.stack_size)
    
    for (i = 0; i < 6; ++i)
        this.Store_gp(i, -8*(i+1), 8)
    
    if fn.block != null {
        funcCtxChain = []
        this.enterContext(funcCtxChain)
        funcCtx = std.back(funcCtxChain)
        funcCtx.cur_funcname = funcname

        for(arg : fn.params_order_var){
            funcCtx.createVar(arg.varname,arg)
        }
        
        for(stmt : fn.block.stmts){
            stmt.compile(funcCtxChain)
        }
        this.leaveContext(funcCtxChain)
    }
    if fn.name == "main"
        writeln("    mov $0, %%rax")

    writeln("L.return.%s:", funcname)
    writeln("    mov %%rbp, %%rsp")
    writeln("    pop %%rbp")
    writeln("    ret")
}