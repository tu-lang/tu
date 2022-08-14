use std

class Block
{
    # [Statement]
    stmts
}


Block::InsertExpressionsHead(initmembers){
    newstmts = []
    for(it : initmembers){
        newstmts[] = new ExpressionStmt(
            it,
            it->line,
            it->column
        )
    }
    std.merge(newstmts,this.stmts)
    this->stmts = newstmts
}