Internal::call_operator(opt,name)
{
    Compiler::writeln("    mov $%ld, %%rdi", opt)
    
    Compiler::Pop("%rdx")
    
    Compiler::Pop("%rsi")
    call(name)
}

Internal::call_object_operator(opt, name,method) {
    
    Compiler::writeln("    mov $%ld, %%rdi", opt)
    Compiler::Pop("%rcx")
    //FIXME: 
    hk<u64> = hash_key(name)
    Compiler::writeln("# [debug] call_object_operator name:%s  hk:%ld",name,hk)
    Compiler::writeln("    mov $%ld,%%rdx",hk)

    Compiler::Pop("%rsi")
    call(method)
}
Internal::gc_malloc(size)
{
    Compiler::writeln("    mov $%ld, %%rdi", size)
    call("runtime_gc_gc_malloc")
}
Internal::gc_malloc()
{
    Compiler::writeln("    mov %%rax, %%rdi")
    call("runtime_gc_gc_malloc")
}
Internal::malloc(size)
{
    Compiler::writeln("    mov $%ld, %%rdi", size)
    call("malloc")
}

Internal::newobject(typ, long data)
{
    Compiler::writeln("    push %%rdi")
    Compiler::writeln("    push %%rsi")

    Compiler::writeln("    mov $%ld, %%rdi", typ)
    if typ != String
        Compiler::writeln("    mov $%ld, %%rsi", data)

    call("runtime_newobject")

    Compiler::writeln("    pop %%rsi")
    Compiler::writeln("    pop %%rdi")
}
Internal::newint(typ, data)
{
    Compiler::writeln("    push %%rdi")
    Compiler::writeln("    push %%rsi")

    Compiler::writeln("    mov $%ld, %%rdi", typ)
    Compiler::writeln("    mov $%s, %%rsi", data)
    call("runtime_newobject")
    Compiler::writeln("    pop %%rsi")
    Compiler::writeln("    pop %%rdi")
}

Internal::newobject2(typ)
{
    Compiler::writeln("    push %%rdi")
    Compiler::writeln("    push %%rsi")

    Compiler::writeln("    mov $%ld, %%rdi", typ)
    Compiler::writeln("    mov %%rax, %%rsi")

    call("runtime_newobject")

    Compiler::writeln("    pop %%rsi")
    Compiler::writeln("    pop %%rdi")
}
Internal::isTrue()
{
    Compiler::writeln("    mov %%rax, %%rdi")
    call("runtime_isTrue")
}
Internal::get_object_value()
{
    Compiler::writeln("    push %%rdi")
    Compiler::writeln("    mov %%rax, %%rdi")
    call("runtime_get_object_value")
    Compiler::writeln("    pop %%rdi")
}

Internal::arr_pushone() {
    
    Compiler::Pop("%rsi")
    
    Compiler::writeln("    mov (%rsp),%rdi")
    call("runtime_arr_pushone")
}

Internal::kv_update() {
    
    Compiler::Pop("%rdx")
    
    Compiler::Pop("%rsi")
    
    Compiler::writeln("    mov (%rsp),%rdi")
    call("runtime_kv_update")
}

Internal::kv_get() {
    
    Compiler::Pop("%rsi")
    
    Compiler::Pop("%rdi")
    call("runtime_kv_get")
}
Internal::call(funcname)
{
    Compiler::writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
    Compiler::writeln("    mov %%rax, %%r10")
    Compiler::writeln("    mov $%d, %%rax", 0)
    Compiler::writeln("    call *%%r10")
}
Internal::object_member_get(name)
{
    Compiler::Pop("%rdi")
    //FIXME: 
    hk<u64> = hash_key(name)
    Compiler::writeln("# [debug] object_member_get name:%s  hk:%ld",name,hk)
    Compiler::writeln("    mov $%ld,%%rsi",hk)

    call("runtime_object_member_get")

}
Internal::object_func_add(name)
{
    Compiler::Pop("%rdx")
    //FIXME: 
    hk<u64> = hash_key(name)
    Compiler::writeln("# [debug] object_func_add  name:%s  hk:%ld",name,hk)
    Compiler::writeln("    mov $%zu,%%rsi",hk)

    
    Compiler::writeln("    mov (%rsp),%rdi")

    call("runtime_object_func_add")
}
Internal::object_func_addr(name)
{
    
    Compiler::Pop("%rdi")

    hk<u64> = hash_key(name)
    Compiler::writeln("# [debug] object_func_addr name:%s  hk:%ld",name,hk)
    Compiler::writeln("    mov $%ld,%%rsi",hk)

    call("runtime_object_func_addr")
}
