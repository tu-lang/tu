use std
use compiler.ast
use compiler.parser.package
use compiler.parser
use compiler.utils

func registerFunc(fn){
    utils.debugf("compile.registerFunc() funcname:%s",fn.name)

    if std.len(fn.closures) {
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
func registerFuncs(){
    utils.debug("compile.registerFuncs()")
    for f : currentParser.funcs {
        f.funcnameid = f.parser.label() + ".L.funcname." + ast.incr_labelid()
        writeln("    .globl %s", f.funcnameid)
        writeln("%s:", f.funcnameid)
        writeln("    .string \"%s\"",f.beautyName())
        registerFunc(f)
    }
}
func CreateFunction(fn) {
    if fn.isExtern return true
    if fn.block == null return true

    funcname = fn.fullname()
    utils.debugf("compile.CreateFunction()  fullname:%s",funcname)

    //register function label
    lid = fn.parser.label() +".L.funcname." + ast.incr_labelid()
    writeln("   .globl %s",lid)
    writeln("%s:",lid)
    writeln("   .string \"%s\"",fn.beautyName())
    //register function body 
    writeln(".global %s", funcname)
    writeln("%s:", funcname)
    writeln("    push %%rbp")
    writeln("    mov %%rsp, %%rbp")
    writeln("    sub $%d, %%rsp", fn.stack_size)
    
    //params args offset is over rbp + 16；not register
    //for i = 0; i < 6; i += 1
    //    Store_gp(i, -8 * ( i + 1 ), 8)
   
    vardic = fn.getVariadic()
    i = 1
    if fn.block != null {
        ctx = new ast.Context()
        ctx.create()
        funcCtx = ctx.top()
        funcCtx.cur_funcname = funcname

        vardic = fn.getVariadic()
        i = 1
        for(arg : fn.params_order_var){
            funcCtx.createVar(arg.varname,arg)
            //fixme: ignore internal pkg for debug
            match fn.package.full_package {
                "std" | "os" | "string" | "runtime" | "fmt" : continue
            }
            if !arg.structtype && vardic == null {
                arg.compile(ctx)
                count  = ast.incr_labelid()
                writeln("   cmp $0,%%rax")
                writeln("   jne %s.L.args.%d",fn.parser.label(),count)
                // internal.miss_args(i,lid,fn.clsname != "")
                writeln("%s.L.args.%d:",fn.parser.label(),count)
            }
            i += 1

        }
        fn.block.hasctx = true
        fn.block.compile(ctx) 
        ctx.destroy()
    }
    if fn.name == "main"
        writeln("    mov $0, %%rax")

    writeln("%s.L.return.%s:",fn.parser.label(), funcname)
    writeln("    mov %%rbp, %%rsp")
    writeln("    pop %%rbp")
    writeln("    ret")
    writeln("    .size %s , .-%s",funcname,funcname)
}