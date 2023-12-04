use compiler.ast
use std


class ReturnStmt     : ast.Ast { 
    ret 
    func init(line,column){
        super.init(line,column)
    }
    func toString() {
        str = "ReturnStmt("
        if (this.ret) {
            str += "ret="
            str += this.ret.toString()
        }
        str += ")"
        return str
    } 
}
ReturnStmt::compile(ctx)
{
    utils.debugf("gen.ReturnExpr::compile()")
    this.record()
    
    if this.ret == null {
        compile.writeln("   mov $0,%%rax")
    }else{
        ret = this.ret.compile(ctx)
        if ret && type(this.ret) == type(gen.AddrExpr) {}
        else if ret && type(ret) == type(gen.StructMemberExpr) {
            sm = ret
            m = sm.ret
            
            compile.LoadMember(m)
        
        }else if ret && type(ret) == type(gen.ChainExpr) {
            ce = ret
            if ce.ismem(ctx) && type(ce.last) == type(MemberCallExpr) {
		    }else{
                if ce.ret {
                    compile.LoadMember(ce.ret)
                }

            }
        }
    }
    for(i = std.len(ctx.ctxs) - 1 ; i >= 0 ; i -= 1){
        p = ctx.ctxs[i]
        funcName = p.cur_funcname
        if funcName != "" {
            compile.writeln("    jmp %s.L.return.%s",compile.currentParser.label(),funcName)
            return null
        } 
    }
    return null
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
    utils.debugf("gen.BreakExpr::compile()")
    this.record()
    
    for(i = std.len(ctx.ctxs) - 1 ; i >= 0 ; i -= 1){
        c = ctx.ctxs[i]
        if c.point && c.end_str != ""  {
            compile.writeln("    jmp %s.%d",c.end_str,c.point)
            return null
        }
    }
    return null
}
class ContinueStmt   : ast.Ast {
    func init(line,column){
        super.init(line,column)
    }  
    func toString() { return "ContinueStmt()" }

}
ContinueStmt::compile(ctx)
{
    utils.debugf("gen.ContinueExpr::compile()")
    this.record()
    
    for(i = std.len(ctx.ctxs) - 1 ; i >= 0 ; i -= 1){
        c = ctx.ctxs[i]
        if c.point && c.continue_str != "" {
            compile.writeln("    jmp %s.%d", c.continue_str, c.point)
            return null
        }
        if c.point && c.start_str != "" {
            compile.writeln("    jmp %s.%d", c.start_str, c.point)
            return null
        }
    }
    return null
}

class GotoStmt   : ast.Ast {
    label = label
    func init(label,line,column){
        super.init(line,column)
    }
}
GotoStmt::compile(ctx){
    utils.debugf("gen.GotoExpr::compile()")
    this.record()
    compile.writeln("   jmp %s",this.label)
    return null
}