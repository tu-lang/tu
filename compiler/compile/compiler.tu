use compiler.utils
use compiler.parser
use compiler.parser.package
use os 
use compiler.internal
use compiler.ast
use fmt

stdpackages = {
    "fmt":true ,         "os":true,             "string":true,          "time":true,
    "std":true ,         "std_map":true,        "std_atomic":true,      "std_regex":true,
    "runtime":true,      "runtime_sys":true,    "runtime_malloc":true,
    "runtime_debug":true,"runtime_gc":true,
}

GlobalPhase   = 1
FunctionPhase = 2

phase = GlobalPhase

func compile(){
    utils.debug("ast.compile()")
    //compute structs
    for pkg : package.packages {
        //need compute the memeber offset early
        for s : pkg.structs {
            if s.isasync continue
            if !s.iscomputed pkg.genStruct(s)
        }
        //cal string id
        for str : pkg.gstrs {
            str.name = fmt.sprintf(
                "string.%s.L.%d",pkg.getuid(),ast.incr_labelid()
            )        
        }
    }

    //register package
    for(p : package.packages){
        if nostd && stdpackages[p.full_package]
            continue
        p.compile()
    }
}
func gcclink(){
    utils.debug("compile.gcclink()")
    // TODO: genearte assembly by self
    // args = "tc -p . -p /usr/local/lib/coasm/"
    links = ""
    if debug 
        links = "gcc  *.s /usr/local/lib/colib/*.o -rdynamic -static -nostdlib -e main"
    else 
        links = "gcc -g *.s /usr/local/lib/colib/*.o -rdynamic -static -nostdlib -e main"
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
    utils.debug("compile.registerMain()")
    writeln("    .global main")
    writeln("main:")
    writeln("    push %%rbp")
    writeln("    mov %%rsp, %%rbp")
    writeln("    sub $%d, %%rsp", 0)

    writeln("    push %%rsi")
    writeln("    push %%rdi")
    
    writeln(
        "   call runtime_gc_init\n" +
        "   call runtime_args_init\n" +
        "   mov $0, %%rax\n" +
        "   call main_main\n"
    )
    writeln("    mov %%rbp, %%rsp")
    writeln("    pop %%rbp")
    writeln("    ret")

}
func _funcs_offsets(fc)
{
    for ( closure : fc.closures ) {
        _funcs_offsets(closure)
    }

    // assign_offsets(fc)
    if fc.isasync {
        genFuture(fc)
    }else{
        genOffsets(fc)
    }

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
        for(fc : c.funcs){
            // assign_offsets(fc)
            genOffsets(fc)
        }
    }

}
//NOTICE: stack version
func genOffsets(fc)
{
    top = 16
    bottom = 0

    for var : fc.params_order_var {
        top = utils.ALIGN_UP(top, 8)
        var.offset = top
        if var.structtype && !var.pointer && var.type <= ast.F64 && var.type >= ast.I8 {
            top += var.size
        }else{
            top += 8
        }
    }
    
    top = utils.ALIGN_UP(top,8)
    fc.ret_stack = top

    order_locals = []
    for local : fc.locals {
        order_locals[] = local
    }
    order_locals = utils.quick_sort(order_locals,fn(l,r){
        return l.varid > r.varid
    })

    for var : order_locals {
        bottom += var.getStackSize(currentParser)
        bottom = utils.ALIGN_UP(bottom, 8)
        var.offset = 0 - bottom
    }
    if fc.is_variadic {
        bottom += 8
        fc.size = 0 - bottom
        bottom += 8
        fc.stack = 0 - bottom

        fc.stack_size = utils.ALIGN_UP(bottom, 16)
    }else{
        fc.stack_size = utils.ALIGN_UP(bottom, 16)
    }
}

func genFuture(fc)
{
    top = 16

    for var : fc.params_order_var {
        top = utils.ALIGN_UP(top, 8)
        var.offset = top
        if var.structtype && !var.pointer && var.type <= ast.F64 && var.type >= ast.I8 {
            top += var.size
        }else{
            top += 8
        }
    }
    
    top = utils.ALIGN_UP(top,8)
    fc.ret_stack = top

    order_locals = []
    for local : fc.locals {
        order_locals[] = local
    }
    order_locals = utils.quick_sort(order_locals,fn(l,r){
        return l.varid > r.varid
    })

    ofs = 0
    for var : order_locals {
        var.offset = ofs
        ofs += var.getStackSize(currentParser)
        ofs = utils.ALIGN_UP(ofs, 8)
    }
    if fc.is_variadic {
        utils.error("async fn unsupport variadic")
    }
    fc.state.size = ofs
    fc.state.align = 8
    fc.state.iscomputed = true

    fc.stack_size = 0
}

func assign_offsets(fc)
{
    utils.debug("compile.assign_offsets()")
    top = 16
    bottom = 0

    gp = 0

    for(var : fc.params_order_var){
        if gp + 1 < GP_MAX {
            bottom += 8
            bottom = utils.ALIGN_UP(bottom, 8)
            var.offset = 0 - bottom
        } else{
            top = utils.ALIGN_UP(top, 8)
            var.offset = top
            if var.structtype && !var.pointer && var.type <= ast.F64 && var.type >= ast.I8 {
                top += var.size
            }else{
                top += 8
            }
        }
    }
    if fc.is_variadic {
        bottom = 48
    }
    for var : fc.locals {
        bottom += var.getStackSize(currentParser)
        bottom = utils.ALIGN_UP(bottom, 8)
        var.offset = 0 - bottom
    }
    if fc.is_variadic {
        bottom += 8
        //TODO: fc.size = -bottom
        fc.size = 0 - bottom
        bottom += 8
        fc.stack = 0 - bottom
        bottom += 8
        fc.l_stack = 0 - bottom
        bottom += 8
        fc.g_stack = 0 - bottom

        fc.stack_size = utils.ALIGN_UP(bottom, 16)
    }else{
        fc.stack_size = utils.ALIGN_UP(bottom, 16)
    }
}


