
func GenAddr(VarExpr *var){
    
    if var.is_local {
        writeln("    lea %d(%%rbp), %%rax", var.offset)
        return var
    }else{
        full = currentFunc.parser.import[var.package]
        name = full + "_" + var.varname
        writeln("    lea %s(%%rip), %%rax", name)
        return var
    }
    parse_err("AsmError:not support global variable read :%s at line %d co %d\n",
              var.varname,var.line,var.column)
}
func Load(m){
    if m.isclass && !m.pointer return
    if m.pointer
        Load(8,true)
    else
        Load(m.size,m.isunsigned)
    if (m.bitfield) {
        writeln("	shl $%d, %%rax", 64 - m.bitwidth - m.bitoffset)
        if (m.isunsigned)
            writeln("	shr $%d, %%rax", 64 - m.bitwidth)
        else
            writeln("	sar $%d, %%rax", 64 - m.bitwidth)
    }
}
func Load(){
    writeln("    mov (%%rax), %%rax")
}
func Load(size , isunsigned){
    prefix = if isunsigned  "movz" else  "movs"
    match size {
        1 : writeln("   %sbl (%%rax), %%eax",prefix)
        2 : writeln("   %swl (%%rax), %%eax",prefix)
        4 : writeln("  movsxd (%%rax), %%rax")
        8 : writeln("  mov (%%rax), %%rax")
        _ : parse_err("Load size error :%d ",size)
    }

}
func CreateCmp(size){
    if size <= 4    writeln("  cmp $0, %%eax")
    else            writeln("  cmp $0, %%rax")
}
/**
 * @param type
 */
func CreateCmp(){
    writeln("    cmp $0, %%rax")
}
func PushV(v){
    writeln("    mov $%d,%%rax",v)
    Push()
}
func PushS(arg){
    writeln("    push %s",arg)
}
func Push(){
    writeln("    push %%rax")
}
func Pop(arg){
    writeln("    pop %s",arg)
}
func Push_arg(prevCtxChain,fc,fce){
    stack = 0 gp = 0
    current_call_have_im = false
    for(arg : fce.args){
        if (type(arg) == type(VarExpr) && currentFunc){
            var = arg
            if std.exist(var.varname,currentFunc.params_var) {
                var2 = currentFunc.params_var[var.varname]
                if var2 && var2.is_variadic {
                    current_call_have_im = true
                }
            }
        }
    }

    if currentFunc && currentFunc.is_variadic && current_call_have_im
    {
        c = ast.incr_compileridx()
        stack_offset
        if fce.is_delref {
            params = -16
            for (i = 0; i < 5; ++i) {
                writeln("    mov %d(%%rbp),%%rax",params)
                internal.get_object_value()
                writeln("    mov %%rax,%s",Compiler::args64[i])
                params += -8
            }
            writeln("    mov %%rax,%%r9")

            stack_offset = 16
        }else
        {
            stack_offset = 8
            params = -8
            for (i = 0; i < 6; ++i) {
                writeln("    mov %d(%%rbp),%%rax",params)
                writeln("    mov %%rax,%s",args64[i])
                params += -8
            }
        }

        writeln("    mov -8(%%rbp),%%rax")
        internal.get_object_value()

        writeln("    sub $5,%%rax")
        writeln("    mov %%rax,%d(%%rbp)",currentFunc.size)
        writeln("    mov $%d,%%rax",stack_offset)
        writeln("    mov %%rax,%d(%%rbp)",currentFunc.stack)


        writeln("    jmp L.while.end.%d",c)
        writeln("L.while.%d:",c)

        writeln("    mov %d(%%rbp),%%rax",currentFunc.size)
        writeln("    imul $8,%%rax")
        writeln("    add $%d,%%rax",stack_offset)
        writeln("    mov %%rax,%d(%%rbp)",currentFunc.stack)
        writeln("    lea (%%rbp),%%rax")

        writeln("    add %d(%%rbp),%%rax",currentFunc.stack)
        writeln("    mov (%%rax),%%rax")
        writeln("    push %%rax")

        writeln("    sub $1,%d(%%rbp)",currentFunc.size)
        
        writeln("L.while.end.%d:",c)
        writeln("    mov %d(%%rbp),%%rax",currentFunc.size)
        writeln("    cmp $0,%%rax")
        writeln("    jg  L.while.%d",c)

    }else{
        argsize = if fc.is_variadic  5 else 6
        if fce.args.size( < argsize)
            for (std.len(i = 0; i < (argsize - (int)fce.args)); ++i){
                writeln("    push $0")
            }
        
        for (i = std.len(fce.args) - 1; i >= 0; i--) {
            if gp >= GP_MAX {
                stack++
            }
            gp += 1
            ret = fce.args[i].compile(prevCtxChain)
            if ret != null && type(ret) == type(ast.StructMemberExpr) {
                sm = ret
                Load(sm.getMember())
            }else if ret != null && type(ret) == type(ChainExpr) {
                ce = ret
                if type(fce.args[i] != type(ast.AddrExpr) {
                    Load(ce.ret)
                }
            }
            Push()
        }
        
        if func.is_variadic {
            
            if fce.args.size( >= 6 ){
                stack ++
            }
            internal.newobject(std.len(Int,fce.args))

            Push()
        }
    }

    return stack < 0 ? 0 : stack
}