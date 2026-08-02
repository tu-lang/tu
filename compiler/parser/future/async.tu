use string
use std
use compiler.ast
use compiler.parser.scanner
use compiler.parser.package
use compiler.utils
use runtime
use compiler.gen

PollError2  = 0
PollReady   = 1
PollPending = 2
PollError   = 3


class AsyncBlock {
    labelid   = 0 
    state     = null        // varexpr
    endstate  = null
    pollstate = null        // varexpr

    funcname  = ""
    root      = null
    stateid   = 0

    fc        = null        // async fn
    curp      = null        // belong to

    queue     = []
    childs    = []
    stmts     = []
    fn init(fc,root){
        this.root = root
        this.fc   = fc
        if root == null {
            this.root = this
        }
        this.funcname = fc.name
        this.labelid = 0
        this.stateid = 0

        case1 = new gen.MatchCaseExpr(0,0)
        case1.id = this.genstateid()
        this.queue[] = case1
    }
    fn gstatevar(){return this.root.state}
    fn gpollvar(){return this.root.pollstate}

    fn gencasevar(){
        pollvarname = "fut.c." + this.topid()
        casevar = new gen.VarExpr(pollvarname,0,0)
        casevar.structtype = true
        casevar.type = ast.U64
        casevar.size = 8
        this.fc.InsertLocalVar(-1,casevar)
        return casevar
    }
    fn genretvar(isstatic){
        retvarname = "fut.r." + this.topid()
        retvar = new gen.VarExpr(retvarname,0,0)
        retvar.size = 8
        if isstatic {
            retvar.structtype = true
            retvar.type = ast.U64
        }
        this.fc.InsertLocalVar(-1,retvar)
        return retvar
    }
    // mem:async leaf await value slot: static type from poll value return.
    // Dynamic slots store raw i8 as fake Value* → binary_operator SEGV.
    fn genretvarForLeaf(s){
        retvarname = "fut.r." + this.topid()
        retvar = new gen.VarExpr(retvarname,0,0)
        if s == null || !s.isasync || this.isRuntimeFutureStruct(s) {
            retvar.size = 8
            this.fc.InsertLocalVar(-1,retvar)
            return retvar
        }
        poll = s.asyncfn
        if poll == null
            poll = s.getFunc("poll")
        if poll != null && poll.async_value_dynamic {
            retvar.size = 8
            this.fc.InsertLocalVar(-1,retvar)
            return retvar
        }
        vty = null
        if poll != null && std.len(poll.returnTypes) >= 2
            vty = poll.returnTypes[1]
        else if poll != null && std.len(poll.returnTypes) == 1
            vty = poll.returnTypes[0]

        if vty != null && vty.baseType() && vty.base >= ast.I8 && vty.base <= ast.F64 {
            retvar.structtype = true
            retvar.type = vty.base
            sz = 8
            if vty.base == ast.I8 || vty.base == ast.U8
                sz = 1
            else if vty.base == ast.I16 || vty.base == ast.U16
                sz = 2
            else if vty.base == ast.I32 || vty.base == ast.U32 || vty.base == ast.F32
                sz = 4
            retvar.size = sz
            retvar.isunsigned = ast.type_isunsigned(vty.base)
            retvar.pointer = vty.pointer
        }else if vty != null && vty.memType() {
            st = vty.st
            if st == null
                st = package.getStruct(vty.pkg, vty.name)
            retvar.structtype = true
            retvar.type = ast.U64
            retvar.size = 8
            retvar.isunsigned = true
            if st != null {
                retvar.structname = st.name
                full = st.pkg
                if st.parser != null {
                    g = st.parser.getpkgname()
                    if g != ""
                        full = g
                }
                retvar.structpkg = full
            }else{
                retvar.structname = vty.name
                retvar.structpkg = vty.pkg
            }
        }else{
            // Untyped but static returns (e.g. 42.(i8))
            retvar.structtype = true
            retvar.type = ast.U64
            retvar.size = 8
            retvar.isunsigned = true
        }
        this.fc.InsertLocalVar(-1,retvar)
        return retvar
    }
    fn genstateid(){
        stateid = this.root.stateid
        this.root.stateid += 1
        return stateid
    }
    fn get_label_id(){
        ret = ""
        ret += this.topid()
        ret += "_"
        ret += this.labelid 
        this.labelid += 1
        return ret
    }
    fn gen_continue_label(){
        return  this.root.fc.fullname() + "_asyncconti_" + this.get_label_id()
    }
    fn gen_end_label(){
        return this.root.fc.fullname() + "_asyncend_" + this.get_label_id()
    }
    fn gen_start_label(){
        return this.root.fc.fullname()+ "_asyncstart_" + this.get_label_id()
    }
    fn create(){
        case1 = new gen.MatchCaseExpr(0,0)
        case1.id = this.genstateid()

        this.queue[] = case1
    }
    fn merge(o){
        for  b : o.queue {
            this.childs[] = b
        }
        for  b : o.childs {
            this.childs[] = b
        }
    }
    fn createend(){
        case1 = new gen.MatchCaseExpr(0,0)
        case1.id = -1

        fc = new gen.FunCallExpr(0,0)
        fc.p = this.root.curp
        fc.package = "runtime"
        fc.funcname = "futuredone"
        fc.is_pkgcall = true
        case1.blocks[] = fc
        this.queue[]   = case1
    }
    fn topid(){
        return std.tail(this.queue).id
    }
    fn push(stmt){
        case1 = std.tail(this.queue)
        case1.blocks[] = stmt
    }
    fn pushi(i , stmt){
        case1 = this.queue[i]
        case1.blocks[] = stmt
    }
    fn pushendstate(endlabel){
        last = std.tail(this.queue)
        last.blocks[] = new gen.GotoStmt(endlabel,0,0)
    }
}

