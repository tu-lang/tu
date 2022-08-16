class BoolExpr    : Ast { literal }
class CharExpr    : Ast { literal }
class NullExpr    : Ast {         }
class IntExpr     : Ast { literal }
class DoubleExpr  : Ast { literal }
class StringExpr  : Ast { literal name offset }
class ArrayExpr   : Ast { literal }
class MapExpr     : Ast { literal }
class KVExpr      : Ast { key value }
class ClosureExpr : Ast { varname }
class DelRefExpr  : Ast { expr }
class ChainExpr   : Ast {
    first
    last
    fields = [] # array[Ast] 
    ret
}
class VarExpr : Ast {
    varname
    offset
    name
    is_local    = true
    is_variadic = false
    package
    ivalue
    
    structname
    structtype  = false
    structpkg  
    pointer     = false
    
    type
    size    
    isunsigned  = false
    stack       = false
    stacksize   = 0
    
    ret funcpkg funcname
    func init(varname,line,column){
        this.varname = varname
    }
}
class StructMemberExpr : Ast {
    varname
    member
    var
    assign
    ret
}
class AddrExpr   : Ast {
    package
    varname
    expr
}
class IndexExpr : Ast {
    varname
    index
    is_pkgcall
    package
}
class BinaryExpr : Ast {
    opt
    lhs rhs
}
class FunCallExpr : Ast {
    funcname
    package
    # [Ast]
    args
    is_pkgcall
    is_extern
    is_delref
}
class AssignExpr : Ast {
    opt
    lhs rhs
}
class NewClassExpr : Ast {
    package name
    args # [Ast]
}
class BuiltinFuncExpr : Ast {
    funcname expr from
}
class NewExpr : Ast {
    package name
    len
}
class MemberExpr : Ast {
    varname  membername
}
class MemberCallExpr : Ast {
    varname membername
    args # [Ast]
}
class MatchCaseExpr : Ast {
    cond
    block

    defaultCase
    matchCond
    logor # this case is multi complex bitor expression

    label 
    endLabel
    func bitOrToLogOr(expr){
        if type(expr) != type(BinaryExpr) return expr
        node = expr
        //only edit BITOR case ast
        if node.opt != BITOR return expr
        
        this.logor = true
        node.opt = LOGOR
    
        if node.lhs != null {
            if type(node.lhs) != type(BinaryExpr) {
                be = new BinaryExpr(this.line,this.column)
                be.lhs = this.matchCond
                be.opt = EQ
                be.rhs = node.lhs
                node.lhs = be
            }else{
                node.lhs = this.bitOrToLogOr(node.lhs)
            }
        }
        if node.rhs != null {
            if type(node.rhs) != type(BinaryExpr) {
                be = new BinaryExpr(this.line,this.column)
                be.lhs = this.matchCond
                be.opt = EQ
                be.rhs = node.rhs
                node.rhs = be
            }else{
                node.rhs = this.bitOrToLogOr(node.rhs)
            }
        }
        return node
    }
}
class IfCaseExpr : Ast {
    cond
    block
    label endLabel
}
class LabelExpr : Ast {
    label
}
