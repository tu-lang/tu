use string
use std
use compiler.ast
use compiler.parser.scanner
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
    ortt      = null
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
        pollvarname = this.gstatevar().varname + "." + this.topid()
        casevar = new gen.VarExpr(pollvarname,0,0)
        casevar.structtype = true
        casevar.type = ast.U64
        casevar.size = 8
        this.fc.InsertLocalVar(-1,casevar)
        return casevar
    }
    fn genretvar(){
        retvarname = this.gstatevar().varname + "_ret_" + this.topid()
        retvar = new gen.VarExpr(retvarname,0,0)
        retvar.structtype = true
        retvar.type = ast.U64
        retvar.size = 8
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

