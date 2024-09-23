
use compiler.ast
use std
use fmt
use os
use compiler.gen
use compiler.utils

func GenAddr(var){
    if var.is_local {
        if ast.GF().isasync {
            if var.isparam && !var.onmem {
                writeln("   lea %d(%%rbp) , %%rax",var.offset)
                return var
            }
            This = ast.GF().FindLocalVar("this")
            if This == null {
                var.check(false,"this param not found in async fn")
            }
            writeln("    mov %d(%%rbp), %%rax", This.offset)
            writeln("    add $%d , %%rax", var.offset)
        }else{
            writeln("    lea %d(%%rbp), %%rax", var.offset)
        }
        return var
    }else{
        full = currentFunc.parser.getImport(var.package)
        if full == "" var.panic("var not define")
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
    if m.isstruct && !m.pointer return false
    if m.pointer
        LoadSize(8,true)
    else if ast.isfloattk(m.type)
        Loadf(m.type)
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
fn Loadf(ty<i32>){
    match ty {
        ast.F32: writeln("  movss (%%rax), %%xmm0")
        ast.F64: writeln("  movsd (%%rax), %%xmm0")
        _  :    utils.error("unsupport type in loadf")
    }
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
fn CreateFCmp(tk<i32>){
    if tk == ast.F32 {
        writeln("  xorps %%xmm1, %%xmm1")
        writeln("  ucomiss %%xmm1, %%xmm0")
    }else if tk == ast.F64 {
        writeln("  xorpd %%xmm1, %%xmm1")
        writeln("  ucomisd %%xmm1, %%xmm0")
    }else {
        utils.error("unknown typ in create fcmp")
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

fn Pushf(ty<i32>){
    writeln("  sub $8, %%rsp")
    if ty == ast.F32
        writeln("  movss %%xmm0, (%%rsp)")
    else if ty == ast.F64
        writeln("  movsd %%xmm0, (%%rsp)")
    else
        utils.error("unsupport ty in pushf")
}

fn PushfDst(ty<i32>, dst,ofs){
    if ty == ast.F32
        writeln("  movss %%xmm0, %d(%s)",ofs,dst)
    else if ty == ast.F64
        writeln("  movsd %%xmm0, %d(%s)",ofs,dst)
    else
        utils.error("unsupport ty in pushf dst")
}

fn PopMRet(sz<i32>){
    for sz -= 1; sz >= 0 ; sz -= 1 {
        Pop(argm64[int(sz)])
    }
}

func Pop(arg){
    writeln("    pop %s",arg)
}

fn Popf(ty<i32>) {
    if ty == ast.F32
        writeln("  movss (%%rsp), %%xmm0")
    else if ty == ast.F64
        writeln("  movsd (%%rsp), %%xmm0")
    else
        utils.error("unsupport ty in popf")
    writeln("  add $8, %%rsp")

}
