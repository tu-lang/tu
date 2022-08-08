Internal::call_operator(opt,name)
{
    compile.writeln("    mov $%ld, %%rdi", opt)
    
    compile.Pop("%rdx")
    
    compile.Pop("%rsi")
    call(name)
}

Internal::call_object_operator(opt, name,method) {
    
    compile.writeln("    mov $%ld, %%rdi", opt)
    compile.Pop("%rcx")
    //FIXME: 
    hk<u64> = hash_key(name)
    compile.writeln("# [debug] call_object_operator name:%s  hk:%ld",name,hk)
    compile.writeln("    mov $%ld,%%rdx",hk)

    compile.Pop("%rsi")
    call(method)
}
Internal::gc_malloc(size)
{
    compile.writeln("    mov $%ld, %%rdi", size)
    call("runtime_gc_gc_malloc")
}
Internal::gc_malloc()
{
    compile.writeln("    mov %%rax, %%rdi")
    call("runtime_gc_gc_malloc")
}
Internal::malloc(size)
{
    compile.writeln("    mov $%ld, %%rdi", size)
    call("malloc")
}

Internal::newobject(typ, long data)
{
    compile.writeln("    push %%rdi")
    compile.writeln("    push %%rsi")

    compile.writeln("    mov $%ld, %%rdi", typ)
    if typ != String
        compile.writeln("    mov $%ld, %%rsi", data)

    call("runtime_newobject")

    compile.writeln("    pop %%rsi")
    compile.writeln("    pop %%rdi")
}
Internal::newint(typ, data)
{
    compile.writeln("    push %%rdi")
    compile.writeln("    push %%rsi")

    compile.writeln("    mov $%ld, %%rdi", typ)
    compile.writeln("    mov $%s, %%rsi", data)
    call("runtime_newobject")
    compile.writeln("    pop %%rsi")
    compile.writeln("    pop %%rdi")
}

Internal::newobject2(typ)
{
    compile.writeln("    push %%rdi")
    compile.writeln("    push %%rsi")

    compile.writeln("    mov $%ld, %%rdi", typ)
    compile.writeln("    mov %%rax, %%rsi")

    call("runtime_newobject")

    compile.writeln("    pop %%rsi")
    compile.writeln("    pop %%rdi")
}
Internal::isTrue()
{
    compile.writeln("    mov %%rax, %%rdi")
    call("runtime_isTrue")
}
Internal::get_object_value()
{
    compile.writeln("    push %%rdi")
    compile.writeln("    mov %%rax, %%rdi")
    call("runtime_get_object_value")
    compile.writeln("    pop %%rdi")
}

Internal::arr_pushone() {
    
    compile.Pop("%rsi")
    
    compile.writeln("    mov (%rsp),%rdi")
    call("runtime_arr_pushone")
}

Internal::kv_update() {
    
    compile.Pop("%rdx")
    
    compile.Pop("%rsi")
    
    compile.writeln("    mov (%rsp),%rdi")
    call("runtime_kv_update")
}

Internal::kv_get() {
    
    compile.Pop("%rsi")
    
    compile.Pop("%rdi")
    call("runtime_kv_get")
}
Internal::call(funcname)
{
    compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
    compile.writeln("    mov %%rax, %%r10")
    compile.writeln("    mov $%d, %%rax", 0)
    compile.writeln("    call *%%r10")
}
Internal::object_member_get(name)
{
    compile.Pop("%rdi")
    //FIXME: 
    hk<u64> = hash_key(name)
    compile.writeln("# [debug] object_member_get name:%s  hk:%ld",name,hk)
    compile.writeln("    mov $%ld,%%rsi",hk)

    call("runtime_object_member_get")

}
Internal::object_func_add(name)
{
    compile.Pop("%rdx")
    //FIXME: 
    hk<u64> = hash_key(name)
    compile.writeln("# [debug] object_func_add  name:%s  hk:%ld",name,hk)
    compile.writeln("    mov $%zu,%%rsi",hk)

    
    compile.writeln("    mov (%rsp),%rdi")

    call("runtime_object_func_add")
}
Internal::object_func_addr(name)
{
    
    compile.Pop("%rdi")

    hk<u64> = hash_key(name)
    compile.writeln("# [debug] object_func_addr name:%s  hk:%ld",name,hk)
    compile.writeln("    mov $%ld,%%rsi",hk)

    call("runtime_object_func_addr")
}
