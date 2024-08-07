use fmt
use compiler.parser.package
use compiler.ast
use std
use compiler.utils
use compiler.compile
use compiler.internal

class BlockStmt : ast.Ast
{
    stmts = []
    func init(){
        super.init()
    }
}

BlockStmt::InsertStatementsHead(stmts){
    utils.debugf("ast.BlockStmt: InesrtStatementsHead stmts.len:%d",std.len(stmts))
    newstmts = []
    for(it : stmts){
        newstmts[] = it
    }
    std.merge(newstmts,this.stmts)
    this.stmts = newstmts
}
BlockStmt::InsertExpressionsHead(exprs){
    utils.debug("ast.BlockStmt: InsertExpressionsHead exprs.len:%d",std.len(exprs))
    newstmts = []
    for(it : exprs){
        newstmts[] = it
    }
    std.merge(newstmts,this.stmts)
    this.stmts = newstmts
}

BlockStmt::checkAndRmFirstSuperDefine(){
    utils.debugf("ast.BlockStmt: checkAndRmFirstSuperDefine")
    if std.len(this.stmts) == 0 return false

    assign = std.head(this.stmts)
    if type(assign) == type(AssignExpr) 
    {
        if assign.opt != ast.ASSIGN return false
        if type(assign.lhs) == type(VarExpr) 
        {
            var = assign.lhs
            if var.varname == "super.0" 
                std.pop_head(this.stmts)
        }
    }
} 
BlockStmt::toString(){
    return "BlockStmt"
}
BlockStmt::compile(ctx){
    if !this.hasctx && std.len(this.stmts) > 0 {
        ctx.create()
    }
    for( stmt : this.stmts ){
        stmt.compile(ctx,true)
    }
    if !this.hasctx && std.len(this.stmts) > 0 {
        ctx.destroy()
    }
}


BlockStmt::checkLastRet(){
    retstmt = new ReturnStmt(this.line,this.column)
    if std.len(this.stmts) == 0 {
        this.stmts[] = retstmt
    }else{
        lastexpr = this.stmts[std.len(this.stmts) - 1]
        if type(lastexpr) != type(ReturnStmt) {
            this.stmts[] = retstmt
        }
    }
}