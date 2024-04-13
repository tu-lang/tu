use compiler.ast

func Store_gp(r, offset, sz){
    match sz {
        1:  writeln("    mov %s, %d(%%rbp)", args8[r], offset)
        2:  writeln("    mov %s, %d(%%rbp)", args16[r], offset)
        4:  writeln("    mov %s, %d(%%rbp)", args32[r], offset)
        8:  writeln("    mov %s, %d(%%rbp)", args64[r], offset)
        _ : {
            for (i = 0; i < sz; i += 1) {
                writeln("    mov %s, %d(%%rbp)", args8[r], offset + i)
                writeln("    shr $8, %s", args64[r])
            }
        }
    }

}

func Store(size<u64>) {
    //dyn version
    if size == null {
        Pop("%rdi")
        writeln("    mov %%rax, (%%rdi)")
        return false
    }
    s = size
    //static version need control the size
    Pop("%rdi")
    match s {
        1 : writeln("   mov %%al, (%%rdi)")
        2 : writeln("   mov %%ax, (%%rdi)")
        4 : writeln("   mov %%eax, (%%rdi)")
        _ : writeln("   mov %%rax, (%%rdi)")
    }
}
fn Storef(ty<i32>)
{
    Pop("%rdi")
    if ty == ast.F32
        writeln("   movss %%xmm0, (%%rdi)")
    else if (ty == ast.F64)
        writeln("   movsd %%xmm0, (%%rdi)")
    else 
        utils.error("unkndown storef type")
}
fn StorefNoPop(ty)
{
    if ty == ast.F32
        writeln("   movss %%xmm0, (%%rdi)")
    else if ty == ast.F64
        writeln("   movsd %%xmm0, (%%rdi)")
    else 
        utils.error("unkndown storefnop type")
}
func StoreNoPop(size)
{
    match size {
        1 : writeln("   mov %%al, (%%rdi)")
        2 : writeln("   mov %%ax, (%%rdi)")
        4 : writeln("   mov %%eax, (%%rdi)")
        _ : writeln("   mov %%rax, (%%rdi)")
    }
}