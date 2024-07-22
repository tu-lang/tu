use compiler.utils
use compiler.ast
use compiler.compile

func call_operator(opt,name)
{
    compile.writeln("   push $%d",int(opt))
    call(name)
}

func call_object_operator(opt, name,method) {
    
    hk = utils.hash(name)
    compile.writeln("# [debug] call_object_operator name:%s  hk:%d",name,hk)
    compile.writeln("    mov $%d,%%rdx",hk)
    compile.writeln("   push %%rdx")
    compile.writeln("   push $%d",int(opt))
    call(method)
}
func gc_malloc(size)
{
    if size != null {
        compile.writeln("    push $%d", size)
        call("runtime_gc_malloc")
    }else {
        //pass args by prev expression.compile & %rax
        compile.writeln("    push %%rax")
        call("runtime_gc_malloc")
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
    call("runtime_type")
}
fn type_id2(){
    compile.writeln("   push %%rax")
    call("runtime_type2")
}
func malloc(size)
{
    compile.writeln("    push $%d", size)
    call("malloc")
}
//@typ  ast.Int ... ast.Object
func newobject(typ,data)
{
    if typ != ast.String {
        compile.writeln("    push $0")
        compile.writeln("   mov $%d , %%rax",data)
        compile.Push()
    }
    compile.writeln("   push $%d",typ)

    call("runtime_newobject")
}
fn newclsobject(vid,objsize){
    compile.writeln("   push    $%d",objsize)
    compile.writeln("   lea %s(%%rip) , %%rax",vid)
    compile.Push()

    call("runtime_newclsobject")
}
fn newfuncobject(funcargs,isvarf,retsize){
    compile.writeln("   push $%d",retsize)
    compile.writeln("   push $%d", isvarf)
    compile.writeln("   push $%d",funcargs)
    compile.Push()

    call("runtime_newfuncobject")
}
func newinherit_object(type_id){
    // compile.Pop("%rdi")
    // compile.writeln("   mov $%d , %%rsi",type_id)
    compile.writeln("   push $%d",type_id)
    call("runtime_newinherit_object")
}
use runtime
func newint(typ, data)
{
    compile.writeln("    push $0")
    compile.writeln("    mov $%s , %%rax",data)
    compile.Push()
    compile.writeln("    push $%d", typ)
    call("runtime_newobject")
}

func newfloat()
{
    compile.Pushf(ast.F64)
    compile.writeln("    push $%d", ast.Double)
    call("runtime_newobject")
}

func newobject2(typ)
{
    compile.writeln("    push $0")
    compile.writeln("    push %%rax")
    compile.writeln("    push $%d", typ)

    call("runtime_newobject")
}
func isTrue()
{
    compile.writeln("   push %%rax")
    call("runtime_isTrue")
}
fn get_func_value(){
    compile.writeln("   push %%rax")
    call("runtime_get_func_value")
}
func get_object_value()
{
    compile.writeln("    push %%rax")
    call("runtime_get_object_value")
}

func arr_pushone() {
    
    call("runtime_arr_pushone")
}

func kv_update() {
    
    call("runtime_kv_update")
}

func kv_get() {
    
    call("runtime_kv_get")
}
func call(funcname,add)
{
    compile.writeln("   call %s",funcname)
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
    compile.writeln("    jne  %s.L.args.%d", compile.currentParser.label(),count)
    //filename , funcname 
    compile.writeln("    lea %s(%%rip), %%rdi", compile.currentParser.filenameid)
    compile.writeln("    lea %s(%%rip), %%rsi", compile.currentFunc.funcnameid)
    compile.writeln("    mov $%d , %%rdx",expr.line)
    compile.writeln("    mov $%d , %%rcx",expr.column)
    compile.writeln("    call runtime_miss_objects")
    compile.writeln("%s.L.args.%d:", compile.currentParser.label(),count)
}
func object_member_get(expr,name)
{
    // check_object(expr)
    // compile.Pop("%rdi")
    hk = utils.hash(name)
    compile.writeln("# [debug] object_member_get name:%s  hk:%d",name,hk)
    compile.writeln("   mov $%d,%%rsi",hk)
    compile.writeln("   push %%rsi")

    call("runtime_object_member_get")
}
fn object_member_get2(expr,name)
{
    // check_object(expr)
    // compile.Pop("%rdi")
    hk = utils.hash(name)
    compile.writeln("# [debug] object_member_get name:%s  hk:%d",name,hk)
    compile.writeln("   mov $%d,%%rsi",hk)
    compile.writeln("   push %%rsi")

    call("runtime_object_member_get2")
}
func object_func_add(name)
{
    // compile.Pop("%rdx")
    hk  = utils.hash(name)
    compile.writeln("# [debug] object_func_add  name:%s  hk:%d",name,hk)
    compile.writeln("   mov $%d,%%rsi",hk)
    compile.writeln("   push %%rsi")

    // compile.writeln("    mov (%%rsp),%%rdi")
    call("runtime_object_func_add")
}
func object_func_addr(expr,name)
{
    // check_object(expr) 
    // compile.Pop("%rdi")

    hk = utils.hash(name)
    compile.writeln("# [debug] object_func_addr name:%s  hk:%d",name,hk)
    compile.writeln("   mov $%d,%%rsi",hk)
    compile.writeln("   push %%rsi")

    call("runtime_object_func_addr")
}
fn object_func_addr2(expr,name)
{
    // check_object(expr) 
    // compile.Pop("%rdi")

    hk = utils.hash(name)
    compile.writeln("# [debug] object_func_addr name:%s  hk:%d",name,hk)
    compile.writeln("   mov $%d,%%rsi",hk)
    compile.writeln("   push %%rsi")

    call("runtime_object_func_addr2")
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
    call("runtime_miss_args")
}

fn dynarg_pass(){
    call("runtime_dynarg_pass")
}