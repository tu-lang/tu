use ast

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
    endLabel = "L.match.end." + mainPoint
    
    for(cs : this.cases){
        c = ast.incr_labelid()
        cs.label = "L.match.case." + c
        cs.endLabel = endLabel
    }
    
    if defaultCase == null {
        defaultCase = new MatchCaseExpr(line,column)
        defaultCase.matchCond = this.cond
    }
    defaultCase.label = "L.match.default." + compile.count++
    defaultCase.endLabel = endLabel
    
    for(cs : this.cases){
        be = new BinaryExpr(cs.line,cs.column)
        be.lhs = cs.matchCond
        be.opt = ast.EQ
        be.rhs = cs.cond
        be.compile(ctx)
        
        if !condIsMtype(be,ctx)
            internal.isTrue()
        
        compile.writeln("    cmp $1, %%rax")
        compile.writeln("    je  %s", cs.label)
    }
    
    compile.writeln("   jmp %s", defaultCase.label)
    
    compile.blockcreate(ctx)
    for(cs : this.cases){
        cs.compile(ctx)
    }
    defaultCase.compile(ctx)
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
MatchCaseExpr::compile(ctx){
    this.record()
    compile.writeln("%s:",label)
    
    if block != null {
        for(stmt : block.stmts){
            stmt.compile(ctx)
        } 
    }
    compile.writeln("   jmp %s", endLabel)
    return this
}

