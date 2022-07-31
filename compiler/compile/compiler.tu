use utils
use parser
use os 
use internal

class Compiler {
    ctx # arr[Context*,Context*..]
}

Compiler::init(filename) 
{
    utils.debug("Compiler::init:",filename)

    pkg = new parser.Packge("main","main",false)

    mparser = new parser.Parser(filename,pkg,"main","main")
    mparser.fileno = 1
    mparser.parser()    # token parsering

    pkg.parsers[filename] = mparser

    parser.packages["main"] = pkg

    //check runtime has been parsered
    if std.exist(parser.packages,"runtime") {
        pkg = new parser.Package("runtime","runtime",false) 
        //recursively scan code files
        if !pkg.parse() utils.error("AsmError: runtime lib import failed")
        parser.packages["runtime"] = pkg 
    }
}

Compiler::compile()
{
    //compute structs
    for(pkg : parser.packages){
        //need compute the memeber offset early
        for(s : pkg.structs){
            if !s.iscomputed pkg.genStruct(s)
        }
    }
    //register package
    for(p : parser.packages){
        p.compile()
    }
}
Compiler::link() 
{
    args = "asmer -p . -p /usr/local/lib/coasm/"
    for(pkg : parser.packages){
        for(p : pkg.parsers){
            //add external library
            for(auto l : p.links){
                args += l
            }
        }
    }
    os.shell(args)
}
Compiler::registerMain()
{
    writeln("    .global main")
    writeln("main:")
    writeln("    push %%rbp")
    writeln("    mov %%rsp, %%rbp")
    writeln("    sub $%d, %%rsp", 0)

    writeln("    push %%rsi")
    writeln("    push %%rdi")
    
    internal.call("runtime_gc_gc_init")
    writeln(
    "    pop  %%rdi\n" +
    "    pop  %%rsi\n" +
    "    mov runtime_args_init@GOTPCREL(%%rip), %%rax\n" +
    "    mov %%rax,%%r10\n" +
    "    call *%%r10\n" +
    )
    writeln("    mov %s@GOTPCREL(%%rip), %%rax", "main_main")
    writeln("    mov %%rax, %%r10")
    writeln("    mov $%d, %%rax", 0)
    writeln("    call *%%r10")
    writeln("    mov %%rbp, %%rsp")
    writeln("    pop %%rbp")
    writeln("    ret")

}
Compiler::funcs_offsets(fn)
{
    for ( closure : fn.closures ) {
        funcs_offsets(closure)
    }

    assign_offsets(fn)

}
Compiler::funcs_offsets() 
{
    for (f : parser.funcs) {
        funcs_offsets(f)
    }

}
Compiler::classs_offsets() 
{
    for(c : parser.pkg.classes){
        for(fn : c.funcs){
            assign_offsets(fn)
        }
    }

}

Compiler::assign_offsets(fn)
{
    top = 16
    bottom = 0

    gp = 0

    for(var : fn.params_order_var){
        if gp + 1 < GP_MAX {
            bottom += 8
            bottom = ALIGN_UP(bottom, 8)
            var.offset = -bottom
        } else{
            top = ALIGN_UP(top, 8)
            var.offset = top
            if var.structtype && !var.pointer && var.type <= ast.U64 && var.type >= ast.I8 {
                top += var.size
            }else{
                top += 8
            }
        }
    }
    if fn.is_variadic {
        bottom = 48
    }
    for(var : fn.locals){
        if var.stack {
            bottom += var.size * var.stacksize
        }
        else if var.structtype && !var.pointer && var.type <= ast.U64 && var.type >= ast.I8 {
            bottom += var.size
        }else{
            bottom += 8
        }
        bottom = ALIGN_UP(bottom, 8)
        var.offset = -bottom
    }
    if fn.is_variadic {
        bottom += 8
        fn.size = - bottom
        bottom += 8
        fn.stack = - bottom
        bottom += 8
        fn.l_stack = - bottom
        bottom += 8
        fn.g_stack = - bottom

        fn.stack_size = ALIGN_UP(bottom, 16)
    }else{
        fn.stack_size = ALIGN_UP(bottom, 16)
    }
}

Compiler::enterContext(ctx)
{
    temp = new Context()
    temp.end_str = ""
    temp.start_str = ""
    temp.continue_str = ""
    ctx[] = temp
}
Compiler::leaveContext(ctx){
{
    tempContext = ctx.back()
    std.pop(ctx)
}
