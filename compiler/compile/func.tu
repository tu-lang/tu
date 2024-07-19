use std
use compiler.ast
use compiler.parser.package
use compiler.parser
use compiler.utils

func registerFunc(fc){
    utils.debugf("compile.registerFunc() funcname:%s",fc.name)

    if std.len(fc.closures) {
        for(closure : fc.closures){
            funcname = "func_" + ast.incr_closureidx()
            closure.receiver.varname = fc.parser.getpkgname() + "_" + funcname
            closure.parser = fc.parser
            closure.name   = funcname
            registerFunc(closure)
        }
    }
    currentFunc = fc
    CreateFunction(fc)
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
func CreateFunction(fc) {
    if fc.isExtern return true
    if fc.block == null return true

    funcname = fc.fullname()
    utils.debugf("compile.CreateFunction()  fullname:%s",funcname)

    //register function label
    lid = fc.parser.label() +".L.funcname." + ast.incr_labelid()
    writeln("   .globl %s",lid)
    writeln("%s:",lid)
    writeln("   .string \"%s\"",fc.beautyName())
    //register function body 
    writeln(".global %s", funcname)
    writeln("%s:", funcname)
    writeln("    push %%rbp")
    writeln("    mov %%rsp, %%rbp")
    writeln("    sub $%d, %%rsp", fc.stack_size)
    
    //params args offset is over rbp + 16；not register
    //for i = 0; i < 6; i += 1
    //    Store_gp(i, -8 * ( i + 1 ), 8)
   
    vardic = fc.getVariadic()
    i = 1
    if fc.block != null {
        //check
        fc.block.checkLastRet()
        
        ctx = new ast.Context()
        ctx.create()
        funcCtx = ctx.top()
        funcCtx.cur_funcname = funcname

        vardic = fc.getVariadic()
        i = 1
        for(arg : fc.params_order_var){
            funcCtx.createVar(arg.varname,arg)
            //fixme: ignore internal pkg for debug
            match fc.package.full_package {
                "std" | "os" | "string" | "runtime" | "fmt" : continue
            }
            if !arg.structtype && vardic == null {
                arg.compile(ctx)
                count  = ast.incr_labelid()
                writeln("   cmp $0,%%rax")
                writeln("   jne %s.L.args.%d",fc.parser.label(),count)
                // internal.miss_args(i,lid,fc.clsname != "")
                writeln("%s.L.args.%d:",fc.parser.label(),count)
            }
            i += 1

        }
        fc.block.hasctx = true
        fc.block.compile(ctx) 
        ctx.destroy()
    }
    if fc.name == "main"
        writeln("    mov $0, %%rax")

    writeln("%s.L.return.%s:",fc.parser.label(), funcname)
    writeln("    mov %%rbp, %%rsp")
    writeln("    pop %%rbp")

    args = std.len(fc.params_order_var)
    if fc.mcount > 1
        args += 1
        
    if args > 0 {
        writeln("   pop %d(%%rsp)", (args - 1) * 8 )
        if args > 1 {
            stack = args - 1
            writeln("   add $%d , %%rsp",stack * 8)
        }
    }

    writeln("    ret")
    writeln("    .size %s , .-%s",funcname,funcname)
}