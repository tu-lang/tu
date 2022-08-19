
func Store_gp(r, offset, sz){
    match sz {
        1:  writeln("    mov %s, %d(%%rbp)", args8[r], offset)
        2:  writeln("    mov %s, %d(%%rbp)", args16[r], offset)
        4:  writeln("    mov %s, %d(%%rbp)", args32[r], offset)
        8:  writeln("    mov %s, %d(%%rbp)", args64[r], offset)
        _ : {
            for (i = 0; i < sz; i++) {
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
        return False
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