use compiler.utils
use compiler.ast
use compiler.internal
use compiler.compile
use compiler.parser
use compiler.parser.package

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

KVExpr::compile(ctx,load){
    this.record()
    utils.debugf("gen.KVExpr::compile() gen... k:%s v:%s",this.key,this.value)

    //push key
    this.key.compile(ctx,true)
    compile.Push()
    //push value
    this.value.compile(ctx,true)
    compile.Push()
    return null
}

class IndexExpr : ast.Ast {
    varname = ""
    index
    is_pkgcall
    package = ""
    tyassert
    
    ret
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

IndexExpr::compile(ctx,load) {
    utils.debug("gen.Index::compile() ")
    this.record()
    var = new VarExpr(this.varname,this.line,this.column)
    var.package = this.package

    if this.varname == "" {
        goto COMPILE_INDEX
    }
    match var.getVarType(ctx,this) {
        ast.Var_Obj_Member : { 
            if this.tyassert != null {
                sm = new StructMemberExpr(this.tyassert.pkgname,
                    this.line,this.column
                )
                vv = var.ret
                vv.structpkg = this.tyassert.pkgname
                vv.structname = this.tyassert.name
                sm.member = this.varname
                sm.var    = vv
                sm.compile(ctx,false)
                me = sm.ret
                if me.pointer
                    compile.LoadMember(me)
                compile.Push()
                if !me.pointer && !me.isarr 
                    this.check(false,"must be pointer member or arr")

                this.compileStaticIndex(ctx,me.size)
                compile.writeln("\tadd %%rdi , (%%rsp)")
                compile.Pop("%rax")
                compile.LoadSize(me.size,me.isunsigned)
                return sm
            }            
            compile.GenAddr(var.ret)
            compile.Load()
            compile.Push()
            internal.object_member_get2(this,this.varname)
            compile.Push() 
        }
        ast.Var_Global_Extern | ast.Var_Global_Local | ast.Var_Local :{ 
            compile.GenAddr(var.ret)
            compile.Load()
            compile.Push()
        }
        ast.Var_Global_Extern_Static | ast.Var_Local_Static | ast.Var_Local_Static_Field | ast.Var_Global_Local_Static_Field :{
            return this.compile_static(ctx) 
        }
        ast.Var_Func : {
            this.panic("meme type can't used in indexpr :" + this.toString(""))
        }
        _ : this.check(false,"unkown type indexexpr::compile")
    }
COMPILE_INDEX:
    this.check(this.index != null,"index is null")
    this.index.compile(ctx,true)
    compile.Push()
    //call arr_get(arr,index)
    internal.kv_get()
    return null
}

IndexExpr::assign( ctx , opt ,rhs) {
    utils.debug("gen.IndexExpr::assign() ")
    var = new VarExpr(this.varname,this.line,this.column)
    var.package = this.package
    if this.package == "" && this.varname == "" {
        goto ASSIGN_INDEX
    }

    match var.getVarType(ctx,this) {
        ast.Var_Obj_Member : { 
            if this.tyassert != null {
                sm = new StructMemberExpr(var.package,this.line,this.column)
                sm.member = var.varname
                vv = var.ret
                vv.structpkg = this.tyassert.pkgname
                vv.structname = this.tyassert.name
                sm.var    = vv
                sm.compile(ctx,false)
                me = sm.ret
                if me.pointer
                    compile.LoadMember(me)
                compile.Push()
                if !me.pointer && !me.isarr this.check(false,"must be pointer member")

                this.compileStaticIndex(ctx,me.size)
                compile.writeln("\tadd %%rdi , (%%rsp)")
                oh = new OperatorHelper(ctx,null,null,ast.ASSIGN)
                oh.genRight(false,rhs)
                compile.Cast(rhs.getType(ctx),me.type)
                compile.Store(me.size)
                return sm
            }
            compile.GenAddr(var.ret)
            compile.Load()
            compile.Push()
            internal.object_member_get2(this,this.varname)
            compile.Push() 
        }
        ast.Var_Global_Extern | ast.Var_Global_Local | ast.Var_Local :{ 
            compile.GenAddr(var.ret)
            compile.Load()
            compile.Push()
        }
        ast.Var_Func |
        ast.Var_Global_Local_Static_Field | 
        ast.Var_Global_Extern_Static | 
        ast.Var_Local_Static |
        ast.Var_Local_Static_Field: {
            return this.assign_static(ctx,opt,rhs)
        }
        _: this.check(false,"array index: unkown type index::assign")
    }
ASSIGN_INDEX:
    if !this.index {
        rhs.compile(ctx,true)
        compile.Push()

        internal.arr_pushone()
        return null
    }
    this.index.compile(ctx,true)
    compile.Push()
    rhs.compile(ctx,true)
    compile.Push()
    //call arr_updateone(arr,index,var)
    internal.kv_update()
    return null
    
}
