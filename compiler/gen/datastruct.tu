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

    compile.writeln("   mov %d(%rsp) , %rax",stack * 8)
}

class LabelExpr : ast.Ast {
    label = label
	func init(label,line,column){
		super.init(line,column)
	}
    func toString(){
        return "label expr: " + label
    }
}

LabelExpr::compile(ctx){
	this.record()
	compile.writeln("%s:",label)
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
    lit 
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx)
    {
        this.record()
        internal.newobject(ast.Bool,this.lit)
        return null
    }
    func toString() {
        return "BoolExpr(" + lit + ")"
    }
}
class CharExpr    : ast.Ast { 
    lit 
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx) {
        this.record()
        internal.newobject(ast.Char,this.lit)
        return null
    }
    func toString() {
        return "CharExpr(" + lit + ")"
    }
}
class IntExpr     : ast.Ast { 
    lit 
    func init(line,column){
        super.init(line,column)
    }
    func compile( ctx) {
        this.record()
        internal.newint(ast.Int,this.lit)
        return null
    }
    func toString() {
        return "int(" + lit + ")"
    }
}

class DoubleExpr  : ast.Ast { 
    lit 
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx) {
        this.record()
        internal.newobject(ast.Double,this.lit)
        return null
    }
    func toString() {
        return "DoubleExpr(" + lit + ")"
    }
}
class StringExpr  : ast.Ast { 
    lit name offset 
    func init(line,column){
        super.init(line,column)
    }
    func compile(ctx) {
        this.record()
        if this.name != "" this.check(false,this.toString())
        
        compile.writeln("    lea %s(%%rip), %%rsi", name)
        internal.newobject(ast.String,0)
        return null
    }
    func toString() { 
        return "StringExpr(" + lit + ") line:" + line + " column:" + column 
    }
}

