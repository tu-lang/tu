use string
use std
use compiler.ast
use compiler.parser.scanner
use compiler.parser
use compiler.utils
use runtime
use compiler.gen

// True when e or its subtree holds an await site.
func hasAwaitDeep(e){
    return e != null && (e.hasawait || gen.exprContainsAwait(e))
}

AsyncBlock::parseIfStmt(ifstmt){
    this.push(ifstmt)

    endid = this.gen_end_label()
    this.push( new gen.LabelExpr(endid,0,0))

    for(ifcase : ifstmt.cases){
        newctx = new AsyncBlock(this.fc,this.root)
        newctx.parse(ifcase.block)
        child = newctx.queue[0]
        ifblock = new gen.BlockStmt()

        ifblock.stmts[] = this.genstate(child)
        ifblock.stmts[] = this.genswitch(child)
        ifcase.block = ifblock

        newctx.pushendstate(endid)
        this.merge(newctx)
    }
    if(ifstmt.elseCase != null){
        newctx = new AsyncBlock(this.fc,this.root)
        newctx.parse(ifstmt.elseCase.block)
        child = newctx.queue[0]
        ifblock = new gen.BlockStmt()

        ifblock.stmts.push_back(this.genstate(child))
        ifblock.stmts.push_back(this.genswitch(child))
        ifstmt.elseCase.block = ifblock

        newctx.pushendstate(endid)
        this.merge(newctx)
    }

    return null
}

AsyncBlock::parseIfStmt2(ifstmt){
    endid = this.gen_end_label()
    for(ifcase : ifstmt.cases){
        newctx = new AsyncBlock(this.fc,this.root)
        newctx.parse(ifcase.block)
        newctx.pushendstate(endid) 
        this.merge(newctx)

        ifs = new gen.IfStmt(0,0)
        ifc = new gen.IfCaseExpr(0,0)
        if(hasAwaitDeep(ifcase.cond)){
           ifc.cond = this.genawait(ifcase.cond,null) 
        }else{
            ifc.cond = ifcase.cond
        }

        child = newctx.queue[0]
        ifblock = new gen.BlockStmt()
        ifblock.stmts[] = this.genstate(child)
        ifblock.stmts[] = this.genswitch(child)
        ifc.block = ifblock

        ifs.cases[] = ifc
        this.push(ifs)
    }
    if(ifstmt.elseCase != null){
        newctx = new AsyncBlock(this.fc,this.root)
        newctx.parse(ifstmt.elseCase.block)
        newctx.pushendstate(endid)
        this.merge(newctx)

        child = newctx.queue[0]
        sblock = new gen.BlockStmt()
        sblock.stmts[] = this.genstate(child)
        sblock.stmts[] = this.genswitch(child)

        this.push(sblock)

    }

    this.push( new gen.LabelExpr(endid,0,0))
    return null
}

AsyncBlock::parseWhileStmt(stmt){

    loopstartid = this.gen_continue_label()
    endid = this.gen_end_label()
    newctx = new AsyncBlock(this.fc,this.root)
    stmt.breakid = endid
    stmt.continueid = loopstartid

    stmt.dead = true
    newblock = new gen.BlockStmt()
    newblock.stmts[] = new gen.LabelExpr(loopstartid,0,0)
    if(stmt.cond != null){
        ifs = new gen.IfStmt(0,0)
        if(hasAwaitDeep(stmt.cond))
            ifs.hasawait = true
        ifc = new gen.IfCaseExpr(0,0)
        ifc.cond = stmt.cond
        ifblock = new gen.BlockStmt()
        ifc.block = ifblock

        ifs.cases[] = ifc
        efc = new gen.IfCaseExpr(0,0)
        eblock = new gen.BlockStmt()
        eblock.stmts[] = new gen.GotoStmt(endid,0,0)
        efc.block = eblock
        ifs.elseCase = efc
        newctx.parse(ifs)
    }
    newctx.parse(stmt.block)
    newctx.pushendstate(loopstartid) 
    this.merge(newctx)

    child = newctx.queue[0]
    newblock.stmts[] = this.genstate(child)
    newblock.stmts[] = this.genswitch(child)

    stmt.block = newblock
    this.push(stmt)
    this.push(
        new gen.LabelExpr(endid,0,0),0,0
    )

    return null
}

AsyncBlock::parseForTriStmt(stmt){

    loopstartid = this.gen_start_label() 
    endid = this.gen_end_label()
    continueid = this.gen_continue_label()

    stmt.breakid = endid
    stmt.continueid = loopstartid
    if(hasAwaitDeep(stmt.after)){
        stmt.continueid = continueid
    }
    newctx = new AsyncBlock(this.fc,this.root)
    if(hasAwaitDeep(stmt.init)){
        stmt.init = this.genawait(stmt.init,null)
    }
    if(hasAwaitDeep(stmt.cond)){
        cond = stmt.cond
        newcond = new gen.BoolExpr(0,0)
        newcond.lit = true
        stmt.cond = newcond
        ifs = new gen.IfStmt(0,0)
        ifs.hasawait = true

        ifc = new gen.IfCaseExpr(0,0)
        ifc.cond = cond
        ifblock = new gen.BlockStmt()
        ifc.block = ifblock

        ifs.cases[] = ifc
        efc = new gen.IfCaseExpr(0,0)
        eblock = new gen.BlockStmt()

        eblock.stmts[] = new gen.GotoStmt(endid,0,0)
        efc.block = eblock
        ifs.elseCase = efc
        newctx.parse(ifs)
    }
    newctx.parse(stmt.block)
    if(hasAwaitDeep(stmt.after)){
        newctx.push( 
            new gen.LabelExpr(continueid,0,0)
        )
        stmt.after = newctx.genawait(stmt.after,null)
    }

    newctx.pushendstate(loopstartid) 
    this.merge(newctx)

    newblock = new gen.BlockStmt()
    child = newctx.queue[0]
    newblock.stmts[] = this.genstate(child)
    newblock.stmts[] = this.genswitch(child)

    newblock.stmts[] = new gen.LabelExpr(loopstartid,0,0)

    stmt.block = newblock
    this.push(stmt)

    this.push(
        new gen.LabelExpr(endid,0,0)
    )

    return null
}

AsyncBlock::parseForRangeStmt(stmt){
    loopstartid = this.gen_continue_label()
    endid = this.gen_end_label()
    newctx = new AsyncBlock(this.fc,this.root)

    stmt.breakid = endid
    stmt.continueid = loopstartid

    newblock = new gen.BlockStmt()
    if(hasAwaitDeep(stmt.obj)){
        stmt.obj = this.genawait(stmt.obj,null)
    }

    newctx.parse(stmt.block)
    newctx.pushendstate(loopstartid) 
    this.merge(newctx)

    child = newctx.queue[0]
    newblock.stmts[] = this.genstate(child)
    newblock.stmts[] = this.genswitch(child)
    newblock.stmts[] = new gen.LabelExpr(loopstartid,0,0)

    stmt.block = newblock
    this.push(stmt)
    this.push(
        new gen.LabelExpr(endid,0,0)
    )

    return null
}

AsyncBlock::parseMatchStmt(stmt){
    endid = this.gen_end_label()
    stmt.breakid = endid

    if type(stmt.cond) != type(gen.VarExpr) {
        if hasAwaitDeep(stmt.cond) {
            // Await site itself or nested in args / chain / literal / binary: lift,
            // then assign to condrecv (inferFromInit, typed from the lifted rhs).
            assignExpr = new gen.AssignExpr(0, 0)
            assignExpr.opt = ast.ASSIGN
            assignExpr.lhs = stmt.condrecv
            assignExpr.rhs = this.lift(stmt.cond)
            stmt.condrecv.inferExpr = assignExpr.rhs
            this.push(assignExpr)
        }else{
            assignExpr = new gen.AssignExpr(0, 0)
            assignExpr.opt = ast.ASSIGN
            assignExpr.lhs = stmt.condrecv
            assignExpr.rhs = stmt.cond
            this.push(assignExpr)
        }
        stmt.cond = stmt.condrecv
    }else if hasAwaitDeep(stmt.cond) {
        stmt.cond = this.genawait(stmt.cond,null)
    }    

    for(case1 : stmt.cases){
        case1.matchCond = stmt.cond
        newctx = new AsyncBlock(this.fc,this.root)
        newctx.parse(case1.block)
        newctx.pushendstate(endid) 
        this.merge(newctx)

        ifs = new gen.IfStmt(0,0)
        ifc = new gen.IfCaseExpr(0,0)

        cond = case1.bitOrToLogOr(case1.cond)
        if !case1.logor {
            be = new gen.BinaryExpr(case1.line,case1.column)
            be.lhs = stmt.cond
            be.opt = ast.EQ
            be.rhs = cond
            be.checkawait()
            cond = be
        }

        if(hasAwaitDeep(cond)){
           ifc.cond = this.genawait(cond,null) 
        }else{
            ifc.cond = cond
        }

        child = newctx.queue[0]
        ifblock = new gen.BlockStmt()
        ifblock.stmts[] = this.genstate(child)
        ifblock.stmts[] = this.genswitch(child)
        ifc.block = ifblock

        ifs.cases[] = ifc
        this.push(ifs)
    }
    if(stmt.defaultCase != null){
        newctx = new AsyncBlock(this.fc,this.root)
        newctx.parse(stmt.defaultCase.block)
        newctx.pushendstate(endid)
        this.merge(newctx)

        child = newctx.queue[0]
        sblock = new gen.BlockStmt()
        sblock.stmts[] = this.genstate(child)
        sblock.stmts[] = this.genswitch(child)
        this.push(sblock)
    }

    this.push(
        new gen.LabelExpr(endid,0,0)
    )

    return null
}

AsyncBlock::parseMultiAssignStmt(stmt){
    if std.len(stmt.rs) > 1 {
        for i = 0 ; i < std.len(stmt.ls) ;i += 1 {
            lexpr = stmt.ls[i]
            rexpr = stmt.rs[i]

            assignExpr = new gen.AssignExpr(lexpr.line,lexpr.column)
            assignExpr.opt = stmt.opt
            assignExpr.lhs = lexpr
            assignExpr.rhs = rexpr
            if(rexpr.hasawait || gen.expressionHasAwait(rexpr) || gen.exprContainsAwait(rexpr)){
                this.liftChildren(assignExpr)
                this.push(assignExpr)
            }else {
                this.push(assignExpr)
            }
        } 
        return null
    }

    rs = stmt.rs[0]
    if gen.isAwaitSite(rs) {
        this.genawait(rs,stmt)
    }else if type(rs) == type(gen.BinaryExpr) && gen.exprContainsAwait(rs) && std.len(stmt.ls) == 1 {
        // sum = a.await + b.await receiver (see genawait)
        this.genawait(rs,stmt)
    }else if gen.exprContainsAwait(rs) {
        // a, b = obj.m(f().await): lift nested awaits, keep the multi-return assign
        stmt.rs[0] = this.lift(rs)
        this.push(stmt)
    }else{
        this.push(stmt)
    }

    return null
}
