use std
use ast
use parser.package
use parser
use utils

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
    utils.debug("compile.registerFunc()")
    for f : currentParser.funcs {
        registerFunc(f)
    }
}
func CreateFunction(fn) {
    if fn.isExtern return True
    if fn.block == null return True

    funcname = fn.fullname()
    utils.debug("compile.CreateFunction()  fullname:%s",funcname)

    //register function label
    lid = ".L.funcname." + ast.incr_labelid()
    writeln("   .globl %s",lid)
    writeln("%s:",lid)
    writeln("   .string \"%s\"",fn.beautyName())
    //register function body 
    writeln(".global %s", funcname)
    writeln("%s:", funcname)
    writeln("    push %%rbp")
    writeln("    mov %%rsp, %%rbp")
    writeln("    sub $%d, %%rsp", fn.stack_size)
    
    for i = 0; i < 6; i += 1
        Store_gp(i, -8 * ( i + 1 ), 8)
   
    vardic = fn.getVariadic()
    i = 1
    if fn.block != null {
        funcCtxChain = []
        blockcreate(funcCtxChain)
        funcCtx = std.tail(funcCtxChain)
        funcCtx.cur_funcname = funcname

        for(arg : fn.params_order_var){
            funcCtx.createVar(arg.varname,arg)
            //fixme: ignore internal pkg for debug
            match fn.package.full_package {
                "std" | "os" | "string" | "runtime" | "fmt" : continue
            }
            if !arg.structtype && vardic == null {
                arg.compile(funcCtx)
                count  = ast.incr_labelid()
                writeln("   cmp $0,%%rax")
                writeln("   jne L.args.%d",count)
                internal.miss_args(i,lid,fn.clsname != "")
                writeln("L.args.%d:",count)
            }
            i += 1

        }
        
        for(stmt : fn.block.stmts){
            stmt.compile(funcCtxChain)
        }
        blockdestroy(funcCtxChain)
    }
    if fn.name == "main"
        writeln("    mov $0, %%rax")

    writeln("L.return.%s:", funcname)
    writeln("    mov %%rbp, %%rsp")
    writeln("    pop %%rbp")
    writeln("    ret")
}