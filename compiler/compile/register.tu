
use ast
use std
use fmt
use os
use gen

func GenAddr(var){
    if var.is_local {
        writeln("    lea %d(%%rbp), %%rax", var.offset)
        return var
    }else{
        full = currentFunc.parser.import[var.package]
        name = full + "_" + var.varname
        writeln("    lea %s(%%rip), %%rax", name)
        return var
    }
    var.panic(
        "AsmError:not support global variable read :%s at line %d co %d\n",
        var.varname,var.line,var.column
    )
}
func LoadMember(m){
    if m.isclass && !m.pointer return False
    if m.pointer
        LoadSize(8,True)
    else
        LoadSize(m.size,m.isunsigned)
    if m.bitfield {
        writeln("	shl $%d, %%rax", 64 - m.bitwidth - m.bitoffset)
        if m.isunsigned
            writeln("	shr $%d, %%rax", 64 - m.bitwidth)
        else
            writeln("	sar $%d, %%rax", 64 - m.bitwidth)
    }
}
func Load(){
    writeln("    mov (%%rax), %%rax")
}
func LoadSize(size , isunsigned){
    prefix = "movs"
    if isunsigned prefix = "movz"
    match size {
        1 : writeln("   %sbl (%%rax), %%eax",prefix)
        2 : writeln("   %swl (%%rax), %%eax",prefix)
        4 : writeln("  movsxd (%%rax), %%rax")
        8 : writeln("  mov (%%rax), %%rax")
        _ : os.panic("Load size error :%d ",size)
    }

}
func CreateCmp(size<u64>){
    if size == null {
        writeln("    cmp $0, %%rax")
    //specific bit size to cmp
    }else {
        if size <= 4    writeln("  cmp $0, %%eax")
        else            writeln("  cmp $0, %%rax")
    }
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
func Push_arg(ctx,fc,fce){
    stack = 0 gp = 0
    current_call_have_im = false
    for(arg : fce.args){
        if (type(arg) == type(gen.VarExpr) && currentFunc){
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
        c = ast.incr_labelid()
        stack_offset = 0
        if fce.is_delref {
            params = -16
            for (i = 0; i < 5; i += 1) {
                writeln("    mov %d(%%rbp),%%rax",params)
                internal.get_object_value()
                writeln("    mov %%rax,%s",compile.args64[i])
                params += -8
            }
            writeln("    mov 16(%%rbp),%%rax")
            if( fce.is_delref )
                internal.get_object_value()
            writeln("    mov %%rax,%%r9")

            stack_offset = 16
        }else
        {
            stack_offset = 8
            params = -8
            for (i = 0; i < 6; i += 1) {
                writeln("    mov %d(%%rbp),%%rax",params)
                writeln("    mov %%rax,%s",args64[i])
                params += -8
            }
        }

        writeln("    mov -8(%%rbp),%%rax")
        internal.get_object_value()
        if fce.is_delref 
            writeln("    sub $6,%%rax")
        else
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
        argsize = 6
        if fc.is_variadic argsize = 5

        if std.len(fce.args) < argsize
            for (i = 0; i < (argsize - std.len(fce.args)); i += 1){
                writeln("    push $0")
            }
        
        for (i = std.len(fce.args) - 1; i >= 0; i -= 1) {
            if gp >= GP_MAX {
                stack += 1
            }
            gp += 1
            ret = fce.args[i].compile(ctx)
            if ret != null && type(ret) == type(gen.StructMemberExpr) {
                sm = ret
                LoadMember(sm.getMember())
            }else if ret != null && type(ret) == type(gen.ChainExpr) {
                ce = ret
                if type(fce.args[i]) != type(gen.AddrExpr) {
                    LoadMember(ce.ret)
                }
            }
            Push()
        }
        
        if fc.is_variadic {
            
            if std.len(fce.args.size) >= 6 {
                stack += 1
            }
            internal.newobject(ast.Int,std.len(fce.args))

            Push()
        }
    }

    if stack < 0 return 0
    else         return stack
}