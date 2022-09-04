use std
use gen

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
        newstmts[] = it
    }
    std.merge(newstmts,this.stmts)
    this.stmts = newstmts
}

Block::checkAndRmFirstSuperDefine(){
    if std.len(this.stmts) return false

    first = std.head(this.stmts)
        assign = first
        if type(assign) == type(gen.AssignExpr) 
        {
            if (assign.opt != ASSIGN) return false
            if type(assign.lhs) == type(gen.VarExpr) 
            {
                var = assign.lhs
                if var.varname == "super" 
                {
                    std.pop_head(this.stmts)
                }
            }
        }

} 