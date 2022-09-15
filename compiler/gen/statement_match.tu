use ast
use utils

class MatchStmt : ast.Ast {
    cond
    cases = []
    defaultCase
    func init(line,column){
        super(line,column)
    }
}
MatchStmt::toString(){
    return "match stmt"
}
MatchStmt::compile(ctx){
    this.record()
    mainPoint = ast.incr_labelid()
    this.endLabel = "L.match.end." + mainPoint
    
    for(cs : this.cases){
        c = ast.incr_labelid()
        cs.label = "L.match.case." + c
        cs.endLabel = this.endLabel
    }
    
    if this.defaultCase == null {
        this.defaultCase = new MatchCaseExpr(this.line,this.column)
        this.defaultCase.matchCond = this.cond
    }
    this.defaultCase.label = "L.match.default." + ast.incr_labelid()
    this.defaultCase.endLabel = this.endLabel
    
    for(cs : this.cases){
        be = new BinaryExpr(cs.line,cs.column)
        be.lhs = cs.matchCond
        be.opt = ast.EQ
        be.rhs = cs.cond
        be.compile(ctx)
        
        if !exprIsMtype(be,ctx)
            internal.isTrue()
        
        compile.writeln("    cmp $1, %%rax")
        compile.writeln("    je  %s", cs.label)
    }
    
    compile.writeln("   jmp %s", this.defaultCase.label)
    
    compile.blockcreate(ctx)
    for(cs : this.cases){
        cs.compile(ctx)
    }
    this.defaultCase.compile(ctx)
    compile.blockdestroy(ctx)

    compile.writeln("L.match.end.%d:",mainPoint)
    return null
}

//TODO: not parser
class MatchCaseExpr : ast.Ast {
    cond
    block

    defaultCase
    matchCond
    logor # this case is multi complex bitor expression

    label 
    endLabel
	func init(line,column){
		super.init(line,column)
	}

}
MatchCaseExpr::toString(){
    return "match stmt expr"
}

MatchCaseExpr::bitOrToLogOr(expr){
    utils.debugf("gen.MatchCaseExpr.bitOrToLogOr(): expr.len:%d",std.len(expr))
	if type(expr) != type(BinaryExpr) return expr
	node = expr
	//only edit ast.BITOR case ast
	if node.opt != ast.BITOR return expr
	
	this.logor = true
	node.opt = ast.LOGOR

	if node.lhs != null {
		if type(node.lhs) != type(BinaryExpr) {
			be = new BinaryExpr(this.line,this.column)
			be.lhs = this.matchCond
			be.opt = ast.EQ
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
			be.opt = ast.EQ
			be.rhs = node.rhs
			node.rhs = be
		}else{
			node.rhs = this.bitOrToLogOr(node.rhs)
		}
	}
	return node
}
MatchCaseExpr::compile(ctx){
    this.record()
    compile.writeln("%s:",this.label)
    
    if this.block != null {
        for(stmt : this.block.stmts){
            stmt.compile(ctx)
        } 
    }
    compile.writeln("   jmp %s", this.endLabel)
    return this
}

