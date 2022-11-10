use utils
use parser
use parser.package
use os 
use internal
use ast

func compile(){
    utils.debug("ast.compile()")
    //compute structs
    for pkg : package.packages {
        //need compute the memeber offset early
        for s : pkg.structs {
            if !s.iscomputed pkg.genStruct(s)
        }
    }
    //register package
    for(p : package.packages){
        p.compile()
    }
}
func link(){
    // TODO: genearte assembly by self
    // args = "tc -p . -p /usr/local/lib/coasm/"
    links = ""
    if debug 
        links = "gcc  *.s /usr/local/lib/coasm/*.s -rdynamic -static -nostdlib -e main"
    else 
        links = "gcc -g *.s /usr/local/lib/coasm/*.s -rdynamic -static -nostdlib -e main"
    for(pkg : package.packages){
        for(p : pkg.parsers){
            //add external library
            for(l : p.links){
                links += " " + l
            }
        }
    }
    utils.debug(links)
    os.shell(links)
}
func registerMain()
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
        fmt.sprintf(
            "%s%s%s%s%s",
            "    pop  %%rdi\n",
            "    pop  %%rsi\n",
            "    mov runtime_args_init@GOTPCREL(%%rip), %%rax\n",
            "    mov %%rax,%%r10\n",
            "    call *%%r10\n"
        )
    )
    writeln("    mov %s@GOTPCREL(%%rip), %%rax", "main_main")
    writeln("    mov %%rax, %%r10")
    writeln("    mov $%d, %%rax", 0)
    writeln("    call *%%r10")
    writeln("    mov %%rbp, %%rsp")
    writeln("    pop %%rbp")
    writeln("    ret")

}
func _funcs_offsets(fn)
{
    for ( closure : fn.closures ) {
        funcs_offsets(closure)
    }

    assign_offsets(fn)

}
func funcs_offsets() 
{
    for (f : currentParser.funcs) {
        _funcs_offsets(f)
    }

}
func classs_offsets() 
{
    for(c : currentParser.pkg.classes){
        for(fn : c.funcs){
            assign_offsets(fn)
        }
    }

}

func assign_offsets(fn)
{
    top = 16
    bottom = 0

    gp = 0

    for(var : fn.params_order_var){
        if gp + 1 < GP_MAX {
            bottom += 8
            bottom = utils.ALIGN_UP(bottom, 8)
            var.offset = 0 - bottom
        } else{
            top = utils.ALIGN_UP(top, 8)
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
        bottom += var.getStackSize()
        bottom = utils.ALIGN_UP(bottom, 8)
        var.offset = 0 - bottom
    }
    if fn.is_variadic {
        bottom += 8
        //TODO: fn.size = -bottom
        fn.size = 0 - bottom
        bottom += 8
        fn.stack = 0 - bottom
        bottom += 8
        fn.l_stack = 0 - bottom
        bottom += 8
        fn.g_stack = 0 - bottom

        fn.stack_size = utils.ALIGN_UP(bottom, 16)
    }else{
        fn.stack_size = utils.ALIGN_UP(bottom, 16)
    }
}

func blockcreate(ctx){
    temp = new ast.Context()
    temp.end_str = ""
    temp.start_str = ""
    temp.continue_str = ""
    ctx[] = temp
}
func blockdestroy(ctx){
    return std.pop(ctx)
}
