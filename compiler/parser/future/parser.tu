use string
use std
use compiler.ast
use compiler.parser.scanner
use compiler.parser
use compiler.utils
use runtime
use compiler.gen

AsyncBlock::parse( stmt ) {

    if type(stmt) == type(gen.WhileStmt) {
        we = stmt
        if we.hasawait {
            return this.parseWhileStmt(we)
        }
        this.push(stmt)
    }else if type(stmt) == type(gen.MatchStmt) {
        ms = stmt
        if ms.hasawait {
            return this.parseMatchStmt(ms)
        }
        this.push(ms)
    }else if type(stmt) == type(gen.IfStmt) {
        ifstmt = stmt
        if ifstmt.hasawait {
            return this.parseIfStmt2(ifstmt)
        }else{
            this.push(ifstmt)
        }
    }else if type(stmt) == type(gen.ForStmt) {
        fe = stmt
        if(fe.hasawait){
            if(fe.range)
                return this.parseForRangeStmt(fe)
            return this.parseForTriStmt(fe)
        }
        this.push(stmt)
    }else if(type(stmt) == type(gen.BlockStmt)){
        block = stmt
        for(s : block.stmts){
            this.parse(s)
        }
    }else if(type(stmt) == type(gen.MultiAssignStmt)){
        ma = stmt
        if(ma.hasawait){
            return this.parseMultiAssignStmt(ma)
        }
        this.push(ma)

    }else if(type(stmt) == type(gen.ReturnStmt)){
        re = stmt
        if(stmt.hasawait){
            ret = []
            ret[] = this.gpollvar()
            first = true
            for(r : re.ret){
                if(first){
                    first = false
                    continue
                }
                if(r.hasawait){
                    ret[] = this.genawait(r,null)
                }else{
                    ret[] = r
                }
            }
            re.ret = ret
            this.editstate(-1)
        }
        this.push(re)

    }else if(type(stmt) == type(gen.BreakStmt)){
        this.push(stmt)
    }else if(type(stmt) == type(gen.ContinueStmt)){
        this.push(stmt)
    }else if(type(stmt) == type(gen.GotoStmt)){
        this.push(stmt)
    }else {
        stmt1 = stmt
        if(stmt.hasawait){
            this.genawait(stmt1.expr,null)
            return null
        }
        this.push(stmt)
    }
    return null
}

AsyncBlock::compile(){
    this.editstate(-1)
    this.createend()
    matche = new gen.MatchStmt(0,0)
    matche.cond = this.root.state

    total = []
    for (case1 : this.queue){
        total[] = case1
    }
    for (case1 : this.childs){
        total[] = case1
    }
    total = utils.quick_sort(total,fn(a,b){
        return a.id < b.id
    })

    for (case1 : total){
        state = new gen.IntExpr(0,0)
        state.literal =  case1.id + ""
        case1.cond = state

        mblock = new gen.BlockStmt()
        mblock.stmts = case1.blocks

        case1.block = mblock
        matche.cases[] = case1
    }
    for(it : this.fc.endstates){
        it.opt = ast.ASSIGN
        it.lhs = this.root.state
        it.rhs = this.root.endstate
    }
    for(it : this.fc.returns){
        it.ret[0] = this.gpollvar()
    }

    this.stmts[] = this.genstate2(1)
    this.stmts[] = this.genpollstate(PollReady)
    this.stmts[] = matche

    ret = new gen.ReturnStmt(0,0)
    ret.ret[] = this.gpollvar()
    this.stmts[] = ret
}

parser.Parser::compileAsync(f){
    ctx = new AsyncBlock(f,null)
    ctx.curp = this
    f.mcount += 1
    state = "s_" + utils.strRand()			
    while(f.getVar(state) != null){
        state = "s_"+ utils.strRand()
    }
    ctx.state = new gen.VarExpr(state,0,0)
    ctx.state.structtype = true
    ctx.state.type = ast.U64
    ctx.pollstate = new gen.VarExpr("poll" + state,0,0)
    ctx.pollstate.structtype = true
    ctx.pollstate.type = ast.U64

    endstate = new gen.IntExpr(0,0)
    endstate.literal = "-1"
    ctx.endstate = endstate

    f.InsertLocalVar(-1,ctx.state)
    f.InsertLocalVar(-1,ctx.pollstate)

    ctx.parse(f.block)
    ctx.compile()
    fcblock = new gen.BlockStmt()
    fcblock.stmts = ctx.stmts

    f.block = fcblock
    return f
}
