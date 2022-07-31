VarExpr::isMemtype(ctx){
    v = getVar(ctx)
    if v.structtype {
        acualPkg = Compiler::parser.import[v.package]
        dst = Package::getStruct(acualPkg,v.structname)
        
        if (dst == null && v.structname != ""){
            this.check(false,"memtype:"+v.package+"."+v.structname+" not define")
        }
        return true
    }
    return false
}
VarExpr::getVar(ctx){
    getVarType(ctx)
    return ret
}

VarType VarExpr::getVarType(ctx)
{
    package = this.package
    if !is_local{
        if (ret = Context::getVar(ctx,package);ret != null)
            return Var_Obj_Member

        if (std.len(Package::packages,package)){
            ret  = Package::packages[package].getGlobalVar(varname)
            
            if ret return Var_Extern_Global
        }
        cpkg = Compiler::currentFunc.parser.getpkgname()
        
        if std.len(Package::packages,cpkg){
            ret = Package::packages[cpkg].getGlobalVar(package)
            if ret return Var_Local_Mem_Global
        }
    }
    
    package = Compiler::currentFunc.parser.getpkgname()
    ret  = Package::packages[package].getGlobalVar(varname)
    if ret return Var_Local_Global
    
    ret = Context::getVar(ctx,this.varname)
    if ret != null{
        f = Compiler::currentFunc
        
        if std.len(f.locals,varname)
            ret = f.locals[varname]
        else if std.len(f.params_var,varname)
            ret = f.params_var[varname]
        else
            parse_err("AsmError:vaiable:%s not define in local or params  at line %d co %d\n",
                varname,this.line,this.column)
            
        return Var_Local
    }
    if (ret = Context::getVar(ctx,"this");ret != null) {
        fn =Compiler::currentFunc
        if (!fn.clsName.empty()){
            c = fn.parser.pkg.getClass(fn.clsName)
            if (c != null && !c.getMember(this.varname).empty()) {
                return Var_Obj_Member
            }
        }
        
    }

    func = null
    funcpkg = this.package
    if (std.len(Package::packages,funcpkg)){
        func = Package::packages[funcpkg].getFunc(varname,false)
    }
    if !func{
        funcpkg = Compiler::currentFunc.parser.getpkgname()
        if (std.len(Package::packages,funcpkg)){
            func = Package::packages[funcpkg].getFunc(varname,false)
        }
    }
    if func{
        funcname = func.name
        return Var_Func
    }    
    parse_err("AsmError:get var type use of undefined variable %s at line %d co %d filename:%s\n",
          varname,this.line,this.column,Compiler::currentFunc.parser.filepath)
}
VarExpr::compile(ctx){
    record()
    match getVarType(ctx)
    {
        Var_Obj_Member : { 
            Compiler::GenAddr(ret)
            Compiler::Load()
            Compiler::Push()
            
            internal.object_member_get(varname)
        }
        Var_Local_Mem_Global : {
            sm = new StructMemberExpr(this.package,this.line,this.column)
            sm.member = this.varname
            sm.var    = this.ret
            sm.compile(ctx)
            return sm
        }
        Var_Extern_Global: 
        Var_Local_Global:
        Var_Local : { 
            Compiler::GenAddr(ret)
            
            if ret.structtype && !ret.pointer && ret.type <= ast.U64 && ret.type >= ast.I8    
                Compiler::Load(ret.size,ret.isunsigned)
            else                                    
                Compiler::Load()
        }
        Var_Func : {  
            fn = funcpkg + "_" + funcname
            utils.debug("found function pointer:%s",fn)
            Compiler::writeln("    mov %s@GOTPCREL(%%rip), %%rax", fn)
        }
    }
    return ret
}
