use compiler.ast
use compiler.utils

class MatchStmt : ast.Ast {
    cond
    cases = []
    defaultCase
    func init(line,column){
        super.init(line,column)
    }
}
MatchStmt::toString(){
    return "match stmt"
}
MatchStmt::compile(ctx){
    utils.debug("gen.MatchStmt::compile()")
    this.record()
    mainPoint = ast.incr_labelid()
    this.endLabel = compile.currentParser.label() + ".L.match.end." + mainPoint
    
    for(cs : this.cases){
        c = ast.incr_labelid()
        cs.label = compile.currentParser.label() + ".L.match.case." + c
        cs.endLabel = this.endLabel
    }
    
    if this.defaultCase == null {
        this.defaultCase = new MatchCaseExpr(this.line,this.column)
        this.defaultCase.matchCond = this.cond
    }
    this.defaultCase.label = compile.currentParser.label() + ".L.match.default." + ast.incr_labelid()
    this.defaultCase.endLabel = this.endLabel
    
    for(cs : this.cases){
        cond = null
        if cs.logor {
            cond = cs.cond
        }else{
            be = new BinaryExpr(cs.line,cs.column)
            be.lhs = cs.matchCond
            be.opt = ast.EQ
            be.rhs = cs.cond
            cond = be
        }
        cond.compile(ctx)

        if !exprIsMtype(cond,ctx)
            internal.isTrue()
        
        compile.writeln("    cmp $1, %%rax")
        compile.writeln("    je  %s", cs.label)
    }
    
    compile.writeln("   jmp %s", this.defaultCase.label)
    
    compile.blockcreate(ctx)

    std.tail(ctx).point = mainPoint
    std.tail(ctx).end_str = compile.currentParser.label() + ".L.match.end"

    for(cs : this.cases){
        cs.compile(ctx)
    }
    this.defaultCase.compile(ctx)
    compile.blockdestroy(ctx)

    compile.writeln("%s.L.match.end.%d:",compile.currentParser.label(),mainPoint)
    return null
}

//TODO: not parser
class MatchCaseExpr : ast.Ast {
    cond
    block

    defaultCase
    matchCond
    logor # this case is multi complex bitor expression

    label  = ""
    endLabel = ""
	func init(line,column){
		super.init(line,column)
	}

}
MatchCaseExpr::toString(){
    return "match stmt expr"
}

MatchCaseExpr::bitOrToLogOr(expr){
    utils.debug("gen.MatchCaseExpr.bitOrToLogOr()" )
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
    utils.debugf("gen.MatchCaseExpr::compile()")
    this.record()
    compile.writeln("%s:",this.label)
    
    if this.block != null {
        this.block.compile(ctx)
    }
    compile.writeln("   jmp %s", this.endLabel)
    return this
}

