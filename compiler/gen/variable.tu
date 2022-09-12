use parser.package
use ast
use std
use compile

class VarExpr : ast.Ast {
    varname = varname
    offset
    name
    is_local    = true
    is_variadic = false
    //FIXME: conflict with import package
    package     = ""
    ivalue
    
    structname
    structtype  = false
    structpkg  
    pointer     = false
    
    type
    size    
    isunsigned  = false
    stack       = false
    stacksize   = 0
    
    ret funcpkg funcname
    func init(varname,line,column){
        super.init(line,column)
    }
}
VarExpr::toString() { return fmt.sprintf("VarExpr(%.%s)",this.package,this.varname) }
VarExpr::isMemtype(ctx){
    v = this.getVar(ctx)
    if v != null && v.structtype {
        acualPkg = compile.parser.import[v.structpkg]
        dst = package.getStruct(acualPkg,v.structname)
        
        if (dst == null && v.structname != ""){
            this.check(false,fmt.sprintf("memtype:%s.%s not define" ,v.package , v.structname))
        }
        return true
    }
    return false
}
VarExpr::getVar(ctx){
    this.getVarType(ctx)
    return this.ret
}

VarExpr::getVarType(ctx)
{
    package = this.package
    if( (this.ret = GP().getGlobalVar(this.package,this.varname)) && this.ret != null){
        return ast.Var_Extern_Global
    }
    if( (this.ret = GP().getGlobalVar("",this.package)) && this.ret != null){
        if (this.ret.structtype)
            return ast.Var_Local_Mem_Global
        else return ast.Var_Obj_Member
    }
    if( (this.ret = GP().getGlobalVar("",this.varname)) && this.ret != null){
        return ast.Var_Local_Global
    }
    this.ret = ast.getVar(ctx,this.package)
    if(this.ret != null){
        return ast.Var_Obj_Member
    } 
    ret = ast.getVar(ctx,this.varname)
    if(ret != null){
        return ast.Var_Local
    }
    fn = GP().getGlobalFunc(this.package,this.varname,false)
    if fn {
        funcname = fn.name
        this.funcpkg = fn.package.getFullName()
        return ast.Var_Func
    }   
    this.panic(
        "AsmError:get var type use of undefined variable %s.%s at line %d co %d filename:%s\n",
        this.package,this.varname,
        this.line,this.column,
        GP().filepath
    )
}
VarExpr::compile(ctx){
    this.record()
    match this.getVarType(ctx)
    {
        ast.Var_Obj_Member : { 
            compile.GenAddr(this.ret)
            compile.Load()
            compile.Push()
            
            internal.object_member_get(this.varname)
        }
        ast.Var_Local_Mem_Global : {
            sm = new StructMemberExpr(this.package,this.line,this.column)
            sm.member = this.varname
            sm.var    = this.ret
            sm.compile(ctx)
            return sm
        }
        ast.Var_Local | ast.Var_Local_Global | ast.Var_Extern_Global: 
        { 
            compile.GenAddr(this.ret)
            //UNSAFE: dyn & native in same expression is unsafe      
            if this.ret.structtype == True && 
               this.ret.pointer == False   && 
               this.ret.type <= ast.U64 && 
               this.ret.type >= ast.I8    
                compile.LoadSize(this.ret.size,this.ret.isunsigned)
            else                                    
                compile.Load()
        }
        ast.Var_Func : {  
            fn = this.funcpkg + "_" + this.funcname
            utils.debug("found function pointer:%s",fn)
            compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", fn)
        }
    }
    return this.ret
}
VarExpr::assign(ctx , opt , rhs){
    this.record()
    match this.getVarType(ctx)
    {
        ast.Var_Obj_Member:{ 
            compile.GenAddr(this.ret)
            compile.Load()
            compile.Push()
            rhs.compile(ctx)
            compile.Push()
            internal.call_object_operator(opt,this.varname,"runtime_object_unary_operator")
            return null
        }
        ast.Var_Local_Mem_Global:{
            sm = new StructMemberExpr(this.package,this.line,this.column)
            sm.member = this.varname
            sm.var    = this.ret

            oh = new OperatorHelper(ctx,sm,rhs,opt)
            oh.var = this.ret
            return oh.gen()
        }
        ast.Var_Extern_Global | ast.Var_Local_Global | ast.Var_Local:{ 
            if this.ret.isMemtype(ctx) {
                oh = new OperatorHelper(ctx,this,rhs,opt)
                oh.var = this.ret
                return oh.gen()
            }
            compile.GenAddr(this.ret)
            compile.Push()

            rhs.compile(ctx)
            compile.Push()
            internal.call_operator(opt,"runtime_unary_operator")
        }
        ast.Var_Func : {  
            this.check(false,"func pointer is lhs in assign expr")
        }
    }
    return null
}