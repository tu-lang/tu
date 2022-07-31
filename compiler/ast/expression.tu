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
    # array[Ast] 
    fields
    ret
}
class VarExpr : Ast {
    varname
    offset
    name
    is_local
    is_variadic
    package
    ivalue
    
    structname  structtype  pointer
    
    type
    size    isunsigned
    stack   stacksize
    
    ret funcpkg funcname
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

    label 
    endLabel
}
class IfCaseExpr : Ast {
    cond
    block
    label endLabel
}
class LabelExpr : Ast {
    label
}
