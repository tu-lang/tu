
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
