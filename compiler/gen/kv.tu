use utils
use ast
use internal
use compile
use parser
use parser.package

class KVExpr  : ast.Ast { 
	key value 
	func init(line,column){
		super.init(line,column)
	}
}
KVExpr::toString() {
    str = "{"
    if this.key   str += this.key.toString()
    str += ":"
    if this.value str += this.value.toString()
    str += "}"
    return str
}

KVExpr::compile(ctx){
    this.record()
    utils.debug("KVExpr: gen... k:%s v:%s",this.key,this.value)

    //push key
    this.key.compile(ctx)
    compile.Push()
    //push value
    this.value.compile(ctx)
    compile.Push()
    return null
}

class IndexExpr : ast.Ast {
    varname
    index
    is_pkgcall
    package
    func init(line,column){
        super.init(line,column)
    }
}
IndexExpr::toString() {
    str = "IndexExpr(index="
    if this.index
        str += this.index.toString()
    str += ")"
    return str
}



IndexExpr::compile(ctx) {
    this.record()
    var = new VarExpr(this.varname,this.line,this.column)
    var.package = this.package

    if this.varname == "" {
        goto COMPILE_INDEX
    }
    match var.getVarType(ctx) {
        ast.Var_Obj_Member : { 
            compile.GenAddr(var.ret)
            compile.Load()
            compile.Push()
            internal.object_member_get(this.varname)
            compile.Push() 
        }
        ast.Var_Extern_Global | ast.Var_Local_Global | ast.Var_Local :{ 
            compile.GenAddr(var.ret)
            compile.Load()
            compile.Push()
        }
        ast.Var_Func | ast.Var_Local_Mem_Global : {
            this.panic("meme type can't used in indexpr :%s",this.toString(""))
        }
    }
COMPILE_INDEX:
    this.check(this.index != null,"index is null")
    this.index.compile(ctx)
    compile.Push()
    //call arr_get(arr,index)
    internal.kv_get()
    return null
}

IndexExpr::assign( ctx , opt ,rhs) {
    var = new VarExpr(this.varname,this.line,this.column)
    var.package = this.package
    if this.package == "" && this.varname == "" {
        goto ASSIGN_INDEX
    }

    match var.getVarType(ctx) {
        ast.Var_Obj_Member : { 
            compile.GenAddr(var.ret)
            compile.Load()
            compile.Push()
            internal.object_member_get(this.varname)
            compile.Push() 
        }
        ast.Var_Extern_Global | ast.Var_Local_Global | ast.Var_Local :{ 
            compile.GenAddr(var.ret)
            compile.Load()
            compile.Push()
        }
        ast.Var_Func | ast.Var_Local_Mem_Global : {
            this.panic("meme type can't used in indexpr :%s",this.toString(""))
        }
    }
ASSIGN_INDEX:
    if !this.index {
        rhs.compile(ctx)
        compile.Push()

        internal.arr_pushone()
        compile.Pop("%rdi")
        return null
    }
    this.index.compile(ctx)
    compile.Push()
    rhs.compile(ctx)
    compile.Push()
    //call arr_updateone(arr,index,var)
    internal.kv_update()
    //rm unuse 
    compile.Pop("%rdi")
    return null
    
}
