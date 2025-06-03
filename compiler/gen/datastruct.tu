use compiler.parser
use std
use fmt
use compiler.ast
use compiler.compile
use os
use compiler.utils

class FuncRTExpr : ast.Ast {
    type    = 1
    base
    pkg     = ""
    name    = ""
    pointer = false
    fn init(line,column){super.init(line,column)}
    fn setMemType() { this.type = 2}
    fn baseType() { return this.type == 1}
    fn memType() { return this.type == 2}
    fn toString() { 
        if this.baseType() {
            return this.s + ast.getTokenString(this.base)
        }
        return this.s + this.pkg + "." + this.name
    }
    fn compile(ctx,load){
        this.record()
        this.check(false,"func return type can't be compile")
    }
}

class ClosPosExpr : ast.Ast {
    pos = pos
    func init(pos,line,column){super.init(line,column)}
    func toString(){ return "ClosPosExpr"}
}

ClosPosExpr::compile(ctx,load){
    this.record()
    //push this.obj
    //push this.obj.func
    //push arg1
    //puish arg2

    compile.writeln("   mov %d(%%rsp) , %%rax",this.pos * 8)
    compile.writeln("   mov (%%rax) , %%rax")
    return null 
}

class  ArgsPosExpr : ast.Ast {
    pos = pos
    func init(pos,line,column){super.init(line,column)}
    func toString(){return "ArgsPosExpr"}
}
ArgsPosExpr::compile(ctx,load){
    this.record()
    //push this.obj
    //push this.obj.func
    //push arg1
    //puish arg2

    compile.writeln("   mov %d(%%rsp) , %%rax",this.pos * 8)
    return null
}

class StackPosExpr : ast.Ast {
    ismem = false
    cur = 0
    total = 0
    pos = -1

    isdyn = false
    fn init(line,column){ super.init(line,column) }
    fn toString(){return "StackPosExpr"}
}

StackPosExpr::compile(ctx , load){
    if this.isdyn
        return this.compile2(ctx,load)
    this.record()

    if this.cur > this.total{
        if this.ismem {
            compile.writeln("    mov $0 , %%rax")
        }else{
            compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
        }
        return null
    }
    //push 3
    //push 2
    // mov 1 %rax

    //push left
    //this.pos = 1 
    count = this.pos
    count += this.cur
    count -= 1
    this.check(this.pos >= 0,"sotmehting wrong here in stack pos expr")
    compile.writeln("    mov %d(%%rsp),%%rax",count * 8)
    return null
}

StackPosExpr::compile2(ctx , load) {
    lid = ast.incr_labelid()
    cfunc = compile.currentFunc
    l1 = cfunc.fullname() + "_mda_" + lid
    l1_end = cfunc.fullname() + "_mda_end_" + lid
    final_end = cfunc.fullname() + "_mda_fend_" + lid
    count = this.pos
    typeinfo = this.pos + 1 + 1 //pos + first arg + retstack
    typeinfo *= 8
    retstack = this.pos + 1
    retstack *= 8

    if this.cur == 1 {
        compile.writeln("    mov %d(%%rsp) , %%rax",this.pos * 8)
        return null
    }
    compile.writeln(
        "   mov %d(%%rsp) , %%rax \n" + 
        "   cmp $%d , 32(%%rax) \n"   +
        "   jge  %s\n",                
        typeinfo,this.cur,l1_end
    )
    if this.ismem {
        compile.writeln("    mov $0 , %%rax")
        compile.writeln("    jmp %s",final_end)
    }else{
        compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
        compile.writeln("    jmp %s",final_end)
    }    
    compile.writeln(
        "%s:", l1_end
    )

    count += this.cur
    count -= 1
    this.check(this.pos >= 0,"sotmehting wrong here in stack pos expr")
    this.check(this.cur >= 2,"sotmething wroong here in cur pos expr")
    compile.writeln(
        "   mov %d(%%rsp) , %%rdi \n" +
        "   mov %d(%%rdi) , %%rax\n",
        retstack,
        (this.cur - 2) * 8
    )
    compile.writeln("%s:",final_end)
    return null
}

class LabelExpr : ast.Ast {
    label = label
	func init(label,line,column){
		super.init(line,column)
	}
    func toString(){
        return "label expr: " + this.label
    }
}

LabelExpr::compile(ctx,load){
	this.record()
	compile.writeln("%s:",this.label)
	return this
}
class NullExpr    : ast.Ast {
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx,load)
    {
        this.record()
        compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
        // internal.newobject(ast.Null,0)
        return null

    }
    func toString() { return "NullExpr()" }
}
class BoolExpr   : ast.Ast { 
    lit = 0
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx,load)
    {
	    utils.debugf("gen.BoolExpr::compile()")
        this.record()
        if this.lit == 1 {
            compile.writeln("    lea runtime_internal_bool_true(%%rip), %%rax")
        }else{
            compile.writeln("    lea runtime_internal_bool_false(%%rip), %%rax")
        }
        // internal.newobject(ast.Bool,this.lit)
        return null
    }
    func toString() {
        return "BoolExpr(" + this.lit + ")"
    }
}
class CharExpr    : ast.Ast { 
    lit = ""
    tyassert
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx,load) {
	    utils.debugf("gen.CharExpr::compile()")
        this.record()
        if this.tyassert != null {
            compile.writeln("	mov $%s,%%rax",this.lit)
            return null
        }
        internal.newobject(ast.Char,string.tonumber(this.lit))
        return null
    }
    func toString() {
        return "CharExpr(" + this.lit + ")"
    }
}
class IntExpr     : ast.Ast { 
    lit = ""
    tyassert
    func init(line,column){
        super.init(line,column)
    }
    func compile( ctx,load) {
	    utils.debugf("gen.IntExpr::compile()")
        this.record()
        if this.tyassert != null {
            compile.writeln("	mov $%s,%%rax",this.lit)
            return null
        }
        internal.newint(ast.Int,this.lit)
        return null
    }
    func toString() {
        return "int(" + this.lit + ")"
    }
}

class FloatExpr  : ast.Ast { 
    lit 
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx,load) {
	    utils.debugf("gen.FloatExpr::compile()")
        this.record()
        internal.newobject(ast.Double,this.lit)
        return null
    }
    func toString() {
        return "FloatExpr(" + this.lit + ")"
    }
    fn tof32(){
        nv<u64> = *this.lit
        nvp<f64*> = &nv
        ori<f64> = *nvp
        ori32<f32> = ori
        nv32p<i64*> = &ori32
        nv32<i64> = *nv32p
        return int(nv32)
    }
}
class StringExpr  : ast.Ast { 
    lit = "" 
    name = "" 
    offset 
    tyassert
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx,load) {
	    utils.debugf("gen.StringExpr::compile()")
        this.record()
        
        real = GP().pkg.get_string(this)
        if real.name == "" {
            this.check(false,"string not computed :")
        }
        if this.tyassert != null {
            compile.writeln("	lea %s(%%rip),%%rax",real.name)
            return null
        }
        
        hk = string.hash64string(
            //cal escape hash value 
            utils.getescapestr(
                real.lit
            )
        )
        compile.writeln("   mov $%s , %%rdx",hk)
        compile.writeln("   push %%rdx")

        compile.writeln("   lea %s(%%rip), %%rsi", real.name)
        compile.writeln("   push %%rsi")
        // compile.writeln("    mov $%s,%%rdx",string.hash64string(this.lit))

        internal.newobject(ast.String,0)
        return null
    }
    func toString() { 
        return "StringExpr(" + this.lit + ") line:" + this.line + " column:" + this.column 
    }
}

class AsmExpr : ast.Ast {
    label = label
    fn init(label,line,column){
        super.init(line,column)
    }
    fn toString(){
        return this.label
    }
}
