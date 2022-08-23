func call_operator(opt,name)
{
    compile.writeln("    mov $%I, %%rdi", opt)
    
    compile.Pop("%rdx")
    
    compile.Pop("%rsi")
    call(name)
}

func call_object_operator(opt, name,method) {
    
    compile.writeln("    mov $%I, %%rdi", opt)
    compile.Pop("%rcx")
    //FIXME: 
    hk<u64> = hash_key(name)
    compile.writeln("# [debug] call_object_operator name:%s  hk:%I",name,hk)
    compile.writeln("    mov $%I,%%rdx",hk)

    compile.Pop("%rsi")
    call(method)
}
func gc_malloc(size<i64>)
{
    if size != null {
        compile.writeln("    mov $%I, %%rdi", size)
        call("runtime_gc_gc_malloc")
    }else {
        //pass args by prev expression.compile & %rax
        compile.writeln("    mov %%rax, %%rdi")
        call("runtime_gc_gc_malloc")
    }
}
func malloc(size)
{
    compile.writeln("    mov $%I, %%rdi", size)
    call("malloc")
}
//@typ  ast.Int ... ast.Object
func newobject(typ<i32>,data)
{
    compile.writeln("    push %%rdi")
    compile.writeln("    push %%rsi")

    compile.writeln("    mov $%I, %%rdi", int(typ))
    if typ != String
        compile.writeln("    mov $%I, %%rsi", data)

    call("runtime_newobject")

    compile.writeln("    pop %%rsi")
    compile.writeln("    pop %%rdi")
}
func newint(typ, data)
{
    compile.writeln("    push %%rdi")
    compile.writeln("    push %%rsi")

    compile.writeln("    mov $%I, %%rdi", typ)
    compile.writeln("    mov $%s, %%rsi", data)
    call("runtime_newobject")
    compile.writeln("    pop %%rsi")
    compile.writeln("    pop %%rdi")
}

func newobject2(typ)
{
    compile.writeln("    push %%rdi")
    compile.writeln("    push %%rsi")

    compile.writeln("    mov $%I, %%rdi", typ)
    compile.writeln("    mov %%rax, %%rsi")

    call("runtime_newobject")

    compile.writeln("    pop %%rsi")
    compile.writeln("    pop %%rdi")
}
func isTrue()
{
    compile.writeln("    mov %%rax, %%rdi")
    call("runtime_isTrue")
}
func get_object_value()
{
    compile.writeln("    push %%rdi")
    compile.writeln("    mov %%rax, %%rdi")
    call("runtime_get_object_value")
    compile.writeln("    pop %%rdi")
}

func arr_pushone() {
    
    compile.Pop("%rsi")
    
    compile.writeln("    mov (%rsp),%rdi")
    call("runtime_arr_pushone")
}

func kv_update() {
    
    compile.Pop("%rdx")
    
    compile.Pop("%rsi")
    
    compile.writeln("    mov (%rsp),%rdi")
    call("runtime_kv_update")
}

func kv_get() {
    
    compile.Pop("%rsi")
    
    compile.Pop("%rdi")
    call("runtime_kv_get")
}
func call(funcname)
{
    compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
    compile.writeln("    mov %%rax, %%r10")
    compile.writeln("    mov $%d, %%rax", 0)
    compile.writeln("    call *%%r10")
}
func object_member_get(name)
{
    compile.Pop("%rdi")
    //FIXME: 
    hk<u64> = hash_key(name)
    compile.writeln("# [debug] object_member_get name:%s  hk:%I",name,hk)
    compile.writeln("    mov $%I,%%rsi",hk)

    call("runtime_object_member_get")

}
func object_func_add(name)
{
    compile.Pop("%rdx")
    //FIXME: 
    hk<u64> = hash_key(name)
    compile.writeln("# [debug] object_func_add  name:%s  hk:%I",name,hk)
    compile.writeln("    mov $%U,%%rsi",hk)

    
    compile.writeln("    mov (%rsp),%rdi")

    call("runtime_object_func_add")
}
func object_func_addr(name)
{
    
    compile.Pop("%rdi")

    hk<u64> = hash_key(name)
    compile.writeln("# [debug] object_func_addr name:%s  hk:%I",name,hk)
    compile.writeln("    mov $%I,%%rsi",hk)

    call("runtime_object_func_addr")
}
func gen_true(){
    Compiler::writeln("    lea runtime_Dtrue(%%rip), %%rax");
    Compiler::writeln("    mov (%%rax), %%rax");
}
func gen_false(){
    Compiler::writeln("    lea runtime_Dfalse(%%rip), %%rax");
    Compiler::writeln("    mov (%%rax), %%rax");
}