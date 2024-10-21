use compiler.ast
use compiler.utils
use compiler.parser

class MatchStmt : ast.Ast {
    cond
    condrecv
    cases = []
    defaultCase
    breakid = ""
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
    ctx.create()

    mainPoint = ast.incr_labelid()
    endLabel = compile.currentParser.label() + ".L.match.end." + mainPoint

    if type(this.cond) != type(VarExpr) {
        compile.GenAddr(this.condrecv)
        compile.Push()
        this.cond.compile(ctx,true)
        compile.Store(this.condrecv.size)
        this.cond = this.condrecv
    }
    
    for(cs : this.cases){
        cs.matchCond = this.cond
        c = ast.incr_labelid()
        cs.label = compile.currentParser.label() + ".L.match.case." + c
        cs.endLabel = endLabel
    }
    
    if this.defaultCase == null {
        this.defaultCase = new MatchCaseExpr(this.line,this.column)
        this.defaultCase.matchCond = this.cond
    }
    this.defaultCase.label = compile.currentParser.label() + ".L.match.default." + ast.incr_labelid()
    this.defaultCase.endLabel = endLabel
    
    for(cs : this.cases){
        cond = cs.bitOrToLogOr(cs.cond)
        if !cs.logor {
            be = new BinaryExpr(cs.line,cs.column)
            be.lhs = this.cond
            be.opt = ast.EQ
            be.rhs = cond
            cond = be
        }
        cond.compile(ctx,true)

        if !exprIsMtype(cond,ctx)
            internal.isTrue()
        
        compile.writeln("    cmp $1, %%rax")
        compile.writeln("    je  %s", cs.label)
    }
    
    compile.writeln("   jmp %s", this.defaultCase.label)
    
    ctx.top().point = mainPoint
    ctx.top().end_str = compile.currentParser.label() + ".L.match.end"

    for(cs : this.cases){
        cs.compile(ctx,true)
    }
    this.defaultCase.compile(ctx,true)
    ctx.destroy()

    compile.writeln("%s.L.match.end.%d:",compile.currentParser.label(),mainPoint)
    return null
}

MatchStmt::compile2(ctx){
    utils.debug("gen.MatchStmt::compile()")
    this.record()
    ctx.create()

    mainPoint = ast.incr_labelid()
    endLabel = compile.currentParser.label() + ".L.match.end." + mainPoint
    
    for(cs : this.cases){
        if ast.GF().isasync()
            cs.matchCond = this.cond        

        c = ast.incr_labelid()
        cs.label = compile.currentParser.label() + ".L.match.case." + c
        cs.endLabel = endLabel
    }
    
    if this.defaultCase == null {
        this.defaultCase = new MatchCaseExpr(this.line,this.column)
        this.defaultCase.matchCond = this.cond
    }
    this.defaultCase.label = compile.currentParser.label() + ".L.match.default." + ast.incr_labelid()
    this.defaultCase.endLabel = endLabel
    
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
        cond.compile(ctx,true)

        if !exprIsMtype(cond,ctx)
            internal.isTrue()
        
        compile.writeln("    cmp $1, %%rax")
        compile.writeln("    je  %s", cs.label)
    }
    
    compile.writeln("   jmp %s", this.defaultCase.label)
    
    ctx.top().point = mainPoint
    ctx.top().end_str = compile.currentParser.label() + ".L.match.end"

    for(cs : this.cases){
        cs.compile(ctx,true)
    }
    this.defaultCase.compile(ctx,true)
    ctx.destroy()

    compile.writeln("%s.L.match.end.%d:",compile.currentParser.label(),mainPoint)
    return null
}

class MatchCaseExpr : ast.Ast {
    cond
    block

    defaultCase
    matchCond
    logor # this case is multi complex bitor expression

    label  = ""
    endLabel = ""

    id     = 0
    blocks = []
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
    node.checkawait()
	return node
}
MatchCaseExpr::compile(ctx,load){
    utils.debugf("gen.MatchCaseExpr::compile()")
    this.record()
    compile.writeln("%s:",this.label)
    
    if this.block != null {
        this.block.compile(ctx)
    }
    compile.writeln("   jmp %s", this.endLabel)
    return this
}

