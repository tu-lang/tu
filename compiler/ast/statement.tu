//TODO: call father init first if child not implement it
class BreakStmt      : Ast {}
class ContinueStmt   : Ast {}
class ReturnStmt     : Ast { ret }
class ExpressionStmt : Ast {
    func init(expr,line,column){
        super(line,column)
        this.expr = expr
    }
}
class IfStmt : Ast {
    func init(line,column){
        //TODO:
        super(line,column)
        this.elseCase = nil
        this.cases    = []
    }
    cases
    elseCase
}
class MatchStmt : Ast {
    func init(line,column){
        super(line,column)
        this.defaultCase = nil
        this.cond = nil
        this.cases = []
    }
    cond
    cases
    defaultCase
}
class GotoStmt   : Ast {
    func init(name,line,column){
        super(line,column)
        this.label = name
    }
    label
}
//TODO: call father init method first if child not implement it
class WhileStmt : Ast {
    cond
    Block
}

class ForStmt : Ast {
    func init(line,column){
        super(line,column)
        this.range = false
    }
    init
    cond
    after
    block

    range
    key
    value
    obj
}