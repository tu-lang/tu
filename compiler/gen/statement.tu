use ast
use std


class ReturnStmt     : ast.Ast { 
    ret 
    func init(line,column){
        super.init(line,column)
    }
    func toString() {
        str = "ReturnStmt("
        if (ret) {
            str += "ret="
            str += ret.toString()
        }
        str += ")"
        return str
    } 
}
ReturnStmt::compile(ctx)
{
    record()
    
    if ret == null {
        compile.writeln("   mov $0,%%rax")
    }else{
        ret = this.ret.compile(ctx)
        if ret && type(ret) == type(ast.StructMemberExpr) {
            sm = ret
            m = sm.ret
            
            compile.Load(m)
        
        }else if ret && type(ret) == type(ast.ChainExpr) {
            ce = ret
            if ce.ret {
                compile.Load(ce.ret)
            }
        }
    }
    for(p : ctx ) {
        funcName = p.cur_funcname
        if funcName != "" 
            compile.writeln("    jmp L.return.%s",funcName)
    }
}
//TODO: not parser
class BreakStmt      : ast.Ast {
    func init(line,column){
        super.init(line,column)
    }  
    func toString() { return "BreakStmt()" }
}
BreakStmt::compile(ctx)
{
    record()
    
    for(c : ctx ) {
        if c.po && c.end_str != ""  {
            compile.writeln("    jmp %s.%d",c.end_str,c.point)
        }
    }
}
class ContinueStmt   : ast.Ast {
    func init(line,column){
        super.init(line,column)
    }  
    func toString() { return "ContinueStmt()" }

}
ContinueStmt::compile(ctx)
{
    record()
    
    for ( c : ctx) {
        if c.po && c.continue_str != "" {
            compile.writeln("    jmp %s.%d", c.continue_str, c.point)
        }
        if c.po && c.start_str != "" {
            compile.writeln("    jmp %s.%d", c.start_str, c.point)
        }
    }
}

class IfCaseExpr : ast.Ast {
    cond
    block
    label endLabel
    func init(line,column){
        super.init(line,column)
    }
}

class GotoStmt   : ast.Ast {
    label = label
    func init(label,line,column){
        super(line,column)
    }
}
GotoStmt::compile(ctx){
    record()
    compile.writeln("   jmp %s",label)
    return null
}