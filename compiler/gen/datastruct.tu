use compiler.parser
use std
use fmt
use compiler.ast
use compiler.compile
use os
use compiler.utils


class  ArgsPosExpr : ast.Ast {
    pos = pos
    func init(pos,line,column){super.init(line,column)}
    func toString(){return "ArgsPosExpr"}
}
ArgsPosExpr::compile(ctx){
    this.record()
    //push this.obj
    //push this.obj.func
    //push arg1
    //puish arg2

    compile.writeln("   mov %d(%%rsp) , %%rax",this.pos * 8)
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

LabelExpr::compile(ctx){
	this.record()
	compile.writeln("%s:",this.label)
	return this
}
class NullExpr    : ast.Ast {
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx)
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
    func compile(ctx)
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
    func compile(ctx) {
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
    func compile( ctx) {
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
    func compile(ctx) {
	    utils.debugf("gen.FloatExpr::compile()")
        this.record()
        internal.newobject(ast.Double,this.lit)
        return null
    }
    func toString() {
        return "FloatExpr(" + this.lit + ")"
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
    func compile(ctx) {
	    utils.debugf("gen.StringExpr::compile()")
        this.record()
        if this.tyassert != null {
            compile.writeln("	lea %s(%%rip),%%rax",this.name)
            return null
        }
        if this.name == "" 
            this.panic("string not computed :" + this.toString(""))
        
        hk = string.hash64string(
            //cal escape hash value 
            utils.getescapestr(
                this.lit
            )
        )
        compile.writeln("   mov $%s , %%rdx",hk)
        compile.writeln("   push %%rdx")

        compile.writeln("   lea %s(%%rip), %%rsi", this.name)
        compile.writeln("   push %%rsi")
        // compile.writeln("    mov $%s,%%rdx",string.hash64string(this.lit))

        internal.newobject(ast.String,0)
        return null
    }
    func toString() { 
        return "StringExpr(" + this.lit + ") line:" + this.line + " column:" + this.column 
    }
}

