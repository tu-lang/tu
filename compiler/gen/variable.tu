use parser.package
use ast
use std

VarExpr::isMemtype(ctx){
    v = this.getVar(ctx)
    if v.structtype {
        acualPkg = compile.parser.import[v.package]
        dst = package.getStruct(acualPkg,v.structname)
        
        if (dst == null && v.structname != ""){
            this.check(false,"memtype:"+v.package+"."+v.structname+" not define")
        }
        return true
    }
    return false
}
VarExpr::getVar(ctx){
    getVarType(ctx)
    return this.ret
}

VarExpr::getVarType(ctx)
{
    package = this.package
    if !is_local {
        if (ret = ast.getVar(ctx,package);ret != null)
            return ast.Var_Obj_Member

        if (std.exist(package.packages,package)){
            ret  = package.packages[package].getGlobalVar(varname)
            
            if ret return ast.Var_Extern_Global
        }
        cpkg = compile.currentFunc.parser.getpkgname()
        
        if std.exist(package.packages,cpkg){
            ret = package.packages[cpkg].getGlobalVar(package)
            if ret return ast.Var_Local_Mem_Global
        }
    }
    
    package = compile.currentFunc.parser.getpkgname()
    ret  = package.packages[package].getGlobalVar(varname)
    if ret return ast.Var_Local_Global
    
    ret = ast.getVar(ctx,this.varname)
    if ret != null{
        f = compile.currentFunc
        
        if std.len(f.locals,varname)
            ret = f.locals[varname]
        else if std.len(f.params_var,varname)
            ret = f.params_var[varname]
        else
            parse_err("AsmError:vaiable:%s not define in local or params  at line %d co %d\n",
                varname,this.line,this.column)
            
        return ast.Var_Local
    }
    if (ret = ast.getVar(ctx,"this");ret != null) {
        fn = compile.currentFunc
        if (!fn.clsName.empty()){
            c = fn.parser.pkg.getClass(fn.clsName)
            if (c != null && !c.getMember(this.varname).empty()) {
                return ast.Var_Obj_Member
            }
        }
        
    }

    func = null
    funcpkg = this.package
    if (std.len(package.packages,funcpkg)){
        func = package.packages[funcpkg].getFunc(varname,false)
    }
    if !func{
        funcpkg = compile.currentFunc.parser.getpkgname()
        if (std.exist(package.packages,funcpkg)){
            func = package.packages[funcpkg].getFunc(varname,false)
        }
    }
    if func{
        funcname = func.name
        return ast.Var_Func
    }    
    parse_err("AsmError:get var type use of undefined variable %s at line %d co %d filename:%s\n",
          varname,this.line,this.column,compile.currentFunc.parser.filepath)
}
VarExpr::compile(ctx){
    record()
    match getVarType(ctx)
    {
        ast.Var_Obj_Member : { 
            compile.GenAddr(ret)
            compile.Load()
            compile.Push()
            
            internal.object_member_get(varname)
        }
        ast.Var_Local_Mem_Global : {
            sm = new StructMemberExpr(this.package,this.line,this.column)
            sm.member = this.varname
            sm.var    = this.ret
            sm.compile(ctx)
            return sm
        }
        ast.Var_Extern_Global: 
        ast.Var_Local_Global:
        ast.Var_Local : { 
            compile.GenAddr(ret)
            
            if ret.structtype && !ret.pointer && ret.type <= ast.U64 && ret.type >= ast.I8    
                compile.Load(ret.size,ret.isunsigned)
            else                                    
                compile.Load()
        }
        ast.Var_Func : {  
            fn = funcpkg + "_" + funcname
            utils.debug("found function pointer:%s",fn)
            compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", fn)
        }
    }
    return ret
}
