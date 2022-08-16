use std

class Block
{
    # [Statement]
    stmts = []
}

Block::InsertStatementsHead(stmts){
    newstmts = []
    for(it : stmts){
        newstmts[] = it
    }
    std.merge(newstmts,this.stmts)
    this.stmts = newstmts
}
Block::InsertExpressionsHead(exprs){
    newstmts = []
    for(it : exprs){
        newstmts[] = new ExpressionStmt(
            it,
            it.line,
            it.column
        )
    }
    std.merge(newstmts,this.stmts)
    this.stmts = newstmts
}

Block::checkAndRmFirstSuperDefine(){
    if std.len(this.stmts) return false

    first = std.head(this.stmts)
    if type(first) == type(ExpressionStmt) 
    {
        assign = stmt.expr
        if type(assign) == type(AssignExpr) 
        {
            if (assign.opt != ASSIGN) return false
            if type(assign.lhs) == type(VarExpr) 
            {
                var = assign.lhs
                if var.varname == "super" 
                {
                    std.pop_head(this.stmts)
                }
            }
        }
    }

} 