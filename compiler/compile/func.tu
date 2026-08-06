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

// Emit a PC label when source line changes (dense pclntab).
func emitPclnPC(line){
    if currentFunc == null || line <= 0 {
        return null
    }
    n = std.len(currentFunc.pcln_pc_lines)
    if n > 0 && currentFunc.pcln_pc_lines[n - 1] == line {
        return null
    }
    lab = "__tu_pc." + currentFunc.fullname() + "." + n
    writeln("%s:", lab)
    currentFunc.pcln_pc_labels[] = lab
    currentFunc.pcln_pc_lines[] = line
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
    if fc.fntype == ast.ExternFunc return true
    if fc.block == null return true

    funcname = fc.fullname()
    utils.debugf("compile.CreateFunction()  fullname:%s",funcname)

    //register function label (also fills funcnameid for closures)
    lid = fc.parser.label() +".L.funcname." + ast.incr_labelid()
    if fc.funcnameid == null || fc.funcnameid == "" {
        fc.funcnameid = lid
    }
    writeln("   .globl %s",lid)
    writeln("%s:",lid)
    writeln("   .string \"%s\"",fc.beautyName())
    //register function body 
    writeln(".global %s", funcname)
    writeln("%s:", funcname)
    writeln("    push %%rbp")
    writeln("    mov %%rsp, %%rbp")
    writeln("    sub $%d, %%rsp", fc.stack_size)
    if fc.stack_size > 1024*1024 {
        utils.error("function stack > 1mb")
    }
    fc.pcln_pc_labels = []
    fc.pcln_pc_lines = []
    
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
            if fc.isasync() continue

            //fixme: ignore internal pkg for debug
            match fc.package.full_package {
                "std" | "os" | "string" | "runtime" | "fmt" : continue
            }
            if !arg.structtype && vardic == null {
                arg.compile(ctx)
                count  = ast.incr_labelid()
                writeln("   cmp $0,%%rax")
                writeln("   jne %s.L.args.%d",fc.parser.label(),count)
                // internal.miss_args(i,lid,fc.fntype != ClssFunc)
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
    // if fc.mcount > 1
        // args += 1
    if fc.isasync() {
        args = 2
    }
        
    if args > 0 {
        writeln("   pop %d(%%rsp)", (args - 1) * 8 )
        if args > 1 {
            stack = args - 1
            writeln("   add $%d , %%rsp",stack * 8)
        }
    }

    writeln("    ret")
    // .size must follow ret at top-level; empty end label cannot precede .size/.data
    writeln("    .size %s , .-%s",funcname,funcname)
    writeln(".global __tu_end_%s", funcname)
    writeln("__tu_end_%s:", funcname)
    writeln("    pause")

    // Phase1.5 pcln fragment + optional __tu_ln dense lines
    nlines = std.len(fc.pcln_pc_lines)
    writeln(".data")
    writeln(".global __tu_pcln.%s", funcname)
    writeln("__tu_pcln.%s:", funcname)
    writeln("    .quad %s", funcname)
    writeln("    .quad __tu_end_%s", funcname)
    writeln("    .quad %s", fc.funcnameid)
    writeln("    .quad %s", fc.parser.filenameid)
    writeln("    .long %d", fc.start_line)
    writeln("    .long %d", nlines)
    if nlines > 0 {
        writeln(".global __tu_ln.%s", funcname)
        writeln("__tu_ln.%s:", funcname)
        i = 0
        while i < nlines {
            writeln("    .quad %s", fc.pcln_pc_labels[i])
            writeln("    .long %d", fc.pcln_pc_lines[i])
            writeln("    .long 0")
            i += 1
        }
    }
    writeln(".text")
}