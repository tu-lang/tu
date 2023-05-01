use utils
use ast
use compile

func call_operator(opt,name)
{
    compile.writeln("   push $%d",int(opt))
    call(name,3)
}

func call_object_operator(opt, name,method) {
    
    hk = utils.hash(name)
    compile.writeln("# [debug] call_object_operator name:%s  hk:%d",name,hk)
    compile.writeln("    mov $%d,%%rdx",hk)
    compile.writeln("   push %%rdx")
    compile.writeln("   push $%d",int(opt))
    call(method,4)
}
func gc_malloc(size)
{
    if size != null {
        compile.writeln("    push $%d", size)
        call("runtime_gc_gc_malloc",1)
    }else {
        //pass args by prev expression.compile & %rax
        compile.writeln("    push %%rax")
        call("runtime_gc_gc_malloc",1)
    }
}
func type_id(id,isobj){
    if(isobj){
        compile.writeln("    push $1")
        compile.writeln("    push %%rax")
    }else{
        compile.writeln("    push $0")
        compile.writeln("    push $%d",id)
    }
    call("runtime_type",2)
}
func malloc(size)
{
    compile.writeln("    push $%d", size)
    call("malloc",1)
}
//@typ  ast.Int ... ast.Object
func newobject(typ,data)
{
    size = 3
    if typ != ast.String {
        size = 2
        compile.writeln("   mov $%d , %%rax",data)
        compile.Push()
    }
    compile.writeln("   push $%d",typ)

    call("runtime_newobject",size)
}
func newinherit_object(type_id){
    // compile.Pop("%rdi")
    // compile.writeln("   mov $%d , %%rsi",type_id)
    compile.writeln("   push $%d",type_id)
    call("runtime_newinherit_object",2)
}
use runtime
func newint(typ, data)
{
    compile.writeln("    mov $%s , %%rax",data)
    compile.Push()
    compile.writeln("    push $%d", typ)
    call("runtime_newobject",2)
}

func newobject2(typ)
{
    compile.writeln("    push %%rax")
    compile.writeln("    push $%d", typ)

    call("runtime_newobject",2)
}
func isTrue()
{
    compile.writeln("   push %%rax")
    call("runtime_isTrue",1)
}
func get_object_value()
{
    compile.writeln("    push %%rax")
    call("runtime_get_object_value",1)
}

func arr_pushone() {
    
    call("runtime_arr_pushone",1)
}

func kv_update() {
    
    call("runtime_kv_update",2)
}

func kv_get() {
    
    call("runtime_kv_get",2)
}
func call(funcname,add)
{
    compile.writeln("   call %s",funcname)
    if add > 0 {
        compile.writeln("   add $%d , %%rsp" , add * 8)
    }
    // compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
    // compile.writeln("    mov %%rax, %%r10")
    // compile.writeln("    mov $%d, %%rax", 0)
    // compile.writeln("    call *%%r10")
}
func check_object(expr){
    // compile.writeln("    mov (%%rsp) , %%rdi")
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
    // check_object(expr)
    // compile.Pop("%rdi")
    hk = utils.hash(name)
    compile.writeln("# [debug] object_member_get name:%s  hk:%d",name,hk)
    compile.writeln("   mov $%d,%%rsi",hk)
    compile.writeln("   push %%rsi")

    call("runtime_object_member_get",2)

}
func object_func_add(name)
{
    // compile.Pop("%rdx")
    hk  = utils.hash(name)
    compile.writeln("# [debug] object_func_add  name:%s  hk:%d",name,hk)
    compile.writeln("   mov $%d,%%rsi",hk)
    compile.writeln("   push %%rsi")

    // compile.writeln("    mov (%%rsp),%%rdi")
    call("runtime_object_func_add",2)
}
func object_func_addr(expr,name)
{
    // check_object(expr) 
    // compile.Pop("%rdi")

    hk = utils.hash(name)
    compile.writeln("# [debug] object_func_addr name:%s  hk:%d",name,hk)
    compile.writeln("   mov $%d,%%rsi",hk)
    compile.writeln("   push %%rsi")

    call("runtime_object_func_addr",2)
}
func gen_true(){
    compile.writeln("    lea runtime_internal_bool_true(%%rip), %%rax")
    // compile.writeln("    mov (%%rax), %%rax")
}
func gen_false(){
    compile.writeln("    lea runtime_internal_bool_false(%%rip), %%rax")
    // compile.writeln("    mov (%%rax), %%rax")
}

func miss_args(pos,funcname,isclass){
    iscls = 0
    if isclass iscls = 1
    compile.writeln("    push $%d",iscls)

    compile.writeln("    lea %s(%%rip), %%rax", funcname)
    compile.writeln("    push %%rax")

    compile.writeln("    push $%d",pos)
    call("runtime_miss_args",3)
}