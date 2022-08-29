use parser.package
use ast
use std

class VarExpr : ast.Ast {
    varname = varname
    offset
    name
    is_local    = true
    is_variadic = false
    package
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
VarExpr::toString() { return "VarExpr(" + this.varname + ")" }
VarExpr::isMemtype(ctx){
    v = this.getVar(ctx)
    if v.structtype {
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
    if !this.is_local {
        if ast.getVar(ctx,package)
            return ast.Var_Obj_Member

        if std.exist(package.packages,package) {
            this.ret  = package.packages[package].getGlobalVar(this.varname)
            
            if this.ret return ast.Var_Extern_Global
        }
        cpkg = compile.currentFunc.parser.getpkgname()
        
        if std.exist(package.packages,cpkg){
            this.ret = package.packages[cpkg].getGlobalVar(package)
            if this.ret {
                if this.ret.structtype
                    return ast.Var_Local_Mem_Global
                else return ast.Var_Local_Global
            }
        }
    }
    
    package = compile.currentFunc.parser.getpkgname()
    ret  = package.packages[package].getGlobalVar(this.varname)
    if ret return ast.Var_Local_Global
    
    ret = ast.getVar(ctx,this.varname)
    if ret != null{
        f = compile.currentFunc
        
        if std.len(f.locals,this.varname)
            ret = f.locals[this.varname]
        else if std.len(f.params_var,this.varname)
            ret = f.params_var[this.varname]
        else
            this.panic(
                "AsmError:vaiable:%s not define in local or params  at line %d co %d\n",
                this.varname,this.line,this.column
            )
            
        return ast.Var_Local
    }

    fc = null
    funcpkg = this.package
    if (std.len(package.packages,funcpkg)){
        fc = package.packages[funcpkg].getFunc(this.varname,false)
    }
    if !fc {
        funcpkg = compile.currentFunc.parser.getpkgname()
        if (std.exist(package.packages,funcpkg)){
            fc = package.packages[funcpkg].getFunc(this.varname,false)
        }
    }
    if fc {
        funcname = fc.name
        return ast.Var_Func
    }    
    this.panic(
        "AsmError:get var type use of undefined variable %s at line %d co %d filename:%s",
          this.varname,this.line,this.column,compile.currentFunc.parser.filepath
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
