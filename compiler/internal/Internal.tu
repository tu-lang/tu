use utils
use ast
use compile

func call_operator(opt,name)
{
    compile.writeln("    mov $%d, %%rdi", int(opt))
    
    compile.Pop("%rdx")
    
    compile.Pop("%rsi")
    call(name)
}

func call_object_operator(opt, name,method) {
    
    compile.writeln("    mov $%d, %%rdi", int(opt))
    compile.Pop("%rcx")
    //FIXME: 32
    hk = utils.hash(name)
    compile.writeln("# [debug] call_object_operator name:%s  hk:%d",name,hk)
    compile.writeln("    mov $%d,%%rdx",hk)

    compile.Pop("%rsi")
    call(method)
}
func gc_malloc(size<i64>)
{
    if size != null {
        compile.writeln("    mov $%d, %%rdi", size)
        call("runtime_gc_gc_malloc")
    }else {
        //pass args by prev expression.compile & %rax
        compile.writeln("    mov %%rax, %%rdi")
        call("runtime_gc_gc_malloc")
    }
}
func malloc(size)
{
    compile.writeln("    mov $%d, %%rdi", size)
    call("malloc")
}
//@typ  ast.Int ... ast.Object
func newobject(typ<i32>,data)
{
    compile.writeln("    push %%rdi")
    compile.writeln("    push %%rsi")

    compile.writeln("    mov $%d, %%rdi", int(typ))
    if typ != ast.String
        compile.writeln("    mov $%d, %%rsi", data)

    call("runtime_newobject")

    compile.writeln("    pop %%rsi")
    compile.writeln("    pop %%rdi")
}
func newinherit_object(type_id){
    compile.Pop("%rdi")
    compile.writeln("   mov $%d , %%rsi",type_id)
    call("runtime_newinherit_object")
}
use runtime
func newint(typ, data)
{
    compile.writeln("    push %%rdi")
    compile.writeln("    push %%rsi")

    compile.writeln("    mov $%d, %%rdi", int(typ))
    compile.writeln("    mov $%s, %%rsi", data)
    call("runtime_newobject")
    compile.writeln("    pop %%rsi")
    compile.writeln("    pop %%rdi")
}

func newobject2(typ)
{
    compile.writeln("    push %%rdi")
    compile.writeln("    push %%rsi")

    compile.writeln("    mov $%d, %%rdi", int(typ))
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
func check_object(expr){
    compile.writeln("    mov (%%rsp) , %rdi")
    compile.writeln("    call runtime_check_object")
    count = ast.incr_labelid()
    compile.writeln("    cmp $0, %%rax")
    compile.writeln("    jne  L.args.%d", count)
    //filename , funcname 
    compile.writeln("    lea %s(%%rip), %%rdi", compile.currentParser.filenameid)
    compile.writeln("    lea %s(%%rip), %%rsi", compile.currentFunc.funcnameid)
    compile.writeln("    mov $%d , %%rdx",expr.line)
    compile.writeln("    mov $%d , %%rcx",expr.column)
    compile.writeln("    call runtime_miss_objects")
    compile.writeln("L.args.%d:", count)
}
func object_member_get(expr,name)
{
    check_object(expr)
    compile.Pop("%rdi")
    hk = utils.hash(name)
    compile.writeln("# [debug] object_member_get name:%s  hk:%d",name,hk)
    compile.writeln("    mov $%d,%%rsi",hk)

    call("runtime_object_member_get")

}
func object_func_add(name)
{
    compile.Pop("%rdx")
    hk  = utils.hash(name)
    compile.writeln("# [debug] object_func_add  name:%s  hk:%d",name,hk)
    compile.writeln("    mov $%U,%%rsi",hk)

    
    compile.writeln("    mov (%rsp),%rdi")

    call("runtime_object_func_add")
}
func object_func_addr(expr,name)
{
    check_object(expr) 
    compile.Pop("%rdi")

    hk = utils.hash(name)
    compile.writeln("# [debug] object_func_addr name:%s  hk:%d",name,hk)
    compile.writeln("    mov $%d,%%rsi",hk)

    call("runtime_object_func_addr")
}
func gen_true(){
    compile.writeln("    lea runtime_Dtrue(%%rip), %%rax")
    compile.writeln("    mov (%%rax), %%rax")
}
func gen_false(){
    compile.writeln("    lea runtime_Dfalse(%%rip), %%rax")
    compile.writeln("    mov (%%rax), %%rax")
}

func type_id(id,isobj){
    if(isobj){
        compile.writeln("    mov %%rax, %%rdi")
        compile.writeln("    mov $1, %%rsi")
    }else{
        compile.writeln("    mov $%d, %%rdi",id)
        compile.writeln("    mov $0, %%rsi")
    }
    call("runtime_type")
}
func miss_args(pos,funcname,isclass){
    compile.writeln("   mov $%d , %rdi",pos)
    compile.writeln("   lea %s(%%rip), %%rsi", funcname)
    iscls = 0
    if isclass iscls = 1
    compile.writeln("   mov $%d , %rdx",iscls)
    call("runtime_miss_args")
}