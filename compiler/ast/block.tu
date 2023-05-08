use std
use compiler.gen
use compiler.utils

class Block
{
    stmts = []
}

Block::InsertStatementsHead(stmts){
    utils.debugf("ast.Block: InesrtStatementsHead stmts.len:%d",std.len(stmts))
    newstmts = []
    for(it : stmts){
        newstmts[] = it
    }
    std.merge(newstmts,this.stmts)
    this.stmts = newstmts
}
Block::InsertExpressionsHead(exprs){
    utils.debug("ast.Block: InsertExpressionsHead exprs.len:%d",std.len(exprs))
    newstmts = []
    for(it : exprs){
        newstmts[] = it
    }
    std.merge(newstmts,this.stmts)
    this.stmts = newstmts
}

Block::checkAndRmFirstSuperDefine(){
    utils.debugf("ast.Block: checkAndRmFirstSuperDefine")
    if std.len(this.stmts) == 0 return false

    assign = std.head(this.stmts)
    if type(assign) == type(gen.AssignExpr) 
    {
        if assign.opt != ASSIGN return false
        if type(assign.lhs) == type(gen.VarExpr) 
        {
            var = assign.lhs
            if var.varname == "super" 
                std.pop_head(this.stmts)
        }
    }

} 