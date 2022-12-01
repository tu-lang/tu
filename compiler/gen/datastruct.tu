use parser
use std
use fmt
use ast
use compile
use os
use utils


class  ArgsPosExpr : ast.Ast {
    pos = pos
    func init(pos,line,column){super.init(line,column)}
    func toString(){return "ArgsPosExpr"}
}
ArgsPosExpr::compile(ctx){
    this.record()
    stack = 0
    if this.pos > 6 {
        utils.error("argspos not support > 6")
    }
    stack += 6 - this.pos

    compile.writeln("   mov %d(%%rsp) , %%rax",stack * 8)
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
        internal.newobject(ast.Null,0)
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
        internal.newobject(ast.Bool,this.lit)
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
        internal.newobject(ast.Char,this.lit)
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

class DoubleExpr  : ast.Ast { 
    lit 
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx) {
	    utils.debugf("gen.DoubleExpr::compile()")
        this.record()
        internal.newobject(ast.Double,this.lit)
        return null
    }
    func toString() {
        return "DoubleExpr(" + this.lit + ")"
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
            this.panic("string not computed :%s" , this.toString(""))
        
        compile.writeln("    lea %s(%%rip), %%rsi", this.name)
        internal.newobject(ast.String,0)
        return null
    }
    func toString() { 
        return "StringExpr(" + this.lit + ") line:" + this.line + " column:" + this.column 
    }
}

