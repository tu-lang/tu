AssignExpr::compile(ctx){
    record()

    utils.debug("AssignExpr: parsing... lhs:%s opt:%s rhs:%s",
          lhs.toString(),
          getTokenString(opt),
          rhs.toString())
    if !this.rhs
        panic("AsmError: right expression is wrong expression:" + this.toString())
    
    f = compile.currentFunc
    if type(lhs) == type(VarExpr) {
        varExpr = lhs
        package = compile.currentFunc.parser.getpkgname() 
        varname = varExpr.varname

        if !varExpr.is_local {

            package = varExpr.package
            if (*var = Context::getVar(ctx,package);var != null) {
                
                compile.GenAddr(var)
                compile.Load()
                compile.Push()

                this.rhs.compile(ctx)
                compile.Push()
                
                internal.call_object_operator(this.opt,varname,"runtime_object_unary_operator")
                return null
            }
            
            cpkg = compile.currentFunc.parser.getpkgname()
            if std.len(package.packages,package){
                varExpr = package.packages[package].getGlobalVar(varname)
            }else if std.len(package.packages,cpkg) {
                varExpr = package.packages[cpkg].getGlobalVar(package)
                sm = new StructMemberExpr(package,this.line,this.column)
                sm.member = varname;
                sm.var    = varExpr;
                this.lhs = sm
                
            }
            
            if !varExpr parse_err("AsmError: assignexpr use of undefined global variable %s at line %d co %d\n",
                varname,this.line,this.column)
        
        }else if package.packages[package].getGlobalVar(varname){
            varExpr = package.packages[package].getGlobalVar(varname)
        }else if std.len(f.params_var,varExpr.varname){
            
            varExpr = f.params_var[varExpr.varname]
            (std.back(ctx)).createVar(varExpr.varname,varExpr)
        }else{
            varExpr = f.locals[varExpr.varname]
            (std.back(ctx)).createVar(varExpr.varname,varExpr)
        }
        
        if varExpr.isMemtype(ctx){
            OperatorHelper oh(ctx,lhs,rhs,this.opt)
            oh.var = varExpr
            return oh.gen()
        }

        compile.GenAddr(varExpr)
        compile.Push()

        this.rhs.compile(ctx)
        compile.Push()
        
        internal.call_operator(this.opt,"runtime_unary_operator")
        return null

    }else if type(lhs) == type(IndexExpr) 
    {
        IndexExpr* index    = lhs
        varname = index.varname
        varExpr
        package    = compile.currentFunc.parser.getpkgname()

        is_member = false
        if index.is_pkgcall {
            package = index.package
            if package == "this" {
                varExpr = f.params_var[package]
                is_member = true
            }else{
                check(package.packages[package] != null,package)
                varExpr = package.packages[package].getGlobalVar(varname)
                if !varExpr panic("AsmError:use of undefined global variable" + varname)
            }
        }else if package.packages[package].getGlobalVar(varname){
            varExpr = package.packages[package].getGlobalVar(varname)
        }else if std.len(f.params_var,varname){
            
            varExpr = f.params_var[varname]
        }else{
            varExpr = f.locals[varname]
        }
        if !varExpr
            parse_err("SyntaxError: not find variable %s at line:%d, column:%d file:%s\n", varname,line,column,compile.currentFunc.parser.filepath)
        std.back(ctx).createVar(varExpr.varname,varExpr

        compile.GenAddr(varExpr)
        compile.Load()
        compile.Push()
        if is_member {
            internal.object_member_get(varname)
            compile.Push()
        }
        
        if !index.index {
            rhs.compile(ctx)
            compile.Push()

            internal.arr_pushone()
            compile.Pop("%rdi")
           return null
        }

        index.index.compile(ctx)
        compile.Push()

        rhs.compile(ctx)
        compile.Push()

        internal.kv_update()
        
        compile.Pop("%rdi")
        return null
    }else if type(lhs) == type(ast.StructMemberExpr) 
    {
        OperatorHelper oh(ctx,lhs,rhs,this.opt)
        return oh.gen()
    }else if type(lhs) == type(ast.DelRefExpr) {
        OperatorHelper oh(ctx,lhs,rhs,this.opt)
        return oh.gen()
    }else if type(lhs) == type(ChainExpr) {
        ce = lhs
        if ce.ismem(ctx){
            OperatorHelper oh(ctx,lhs,rhs,this.opt)
            return oh.gen()
        }
    }
    panic("SyntaxError: can not assign to " + string(type(lhs).name()))
}

BinaryExpr::isMemtype(ctx)
{    
    mhandle = false
    var
    this.check(this.lhs != null)
    
    if type(this.lhs == type(ast.StructMemberExpr) ||  (this.rhs && type(this.rhs) == type(ast.StructMemberExpr) )
        mhandle = true
    
    if type(this.lhs == type(DelRefExpr) || (this.rhs && type(this.rhs) == type(ast.DelRefExpr) )
        mhandle = true
    
    if type(this.lhs == type(VarExpr) {
        var = this.lhs
        var = var.getVar(ctx)
        if var.structtype
            mhandle = true
    }
    if this.rhs && type(this.rhs == type(VarExpr) {
        var = this.rhs
        var = var.getVar(ctx)
        if var.structtype
            mhandle = true
    }
    if type(this.lhs == type(BinaryExpr) {
        b = this.lhs
        if b.isMemtype(ctx) return true
    }
    if this.rhs && type(this.rhs == type(BinaryExpr) {
        b = this.rhs
        if b.isMemtype(ctx) return true
    }
    if type(this.lhs == type(ChainExpr) {
        ce = this.lhs
        if ce.ismem(ctx)
            return true
    }
    if this.rhs && type(this.rhs == type(ChainExpr) {
        ce = this.rhs
        if ce.ismem(ctx)
            return true
    }
    return mhandle
}

BinaryExpr::compile(ctx)
{
    record()

    utils.debug("BinaryExpr: parsing... lhs:%s opt:%s rhs:%s",
          lhs.toString(),
          getTokenString(opt),
          rhs.toString())
    if !this.rhs && (this.opt != BITNOT && this.opt != LOGNOT)
        panic("AsmError: right expression is wrong expression:" + this.toString())
    
    if isMemtype(ctx){
        OperatorHelper oh(ctx,lhs,rhs,this.opt)
        return oh.gen()
    }

    
    this.lhs.compile(ctx)
    compile.Push()

    
    if this.rhs   this.rhs.compile(ctx)
    else            compile.writeln("   mov $0,%%rax")
    compile.Push()

    
    internal.call_operator(this.opt,"runtime_binary_operator")
    return null
}
DelRefExpr::compile(ctx){
    record()
    
    if type(this.expr == type(StringExpr) {
        StringExpr* se = this.expr
        compile.writeln("    lea %s(%%rip), %%rax", se.name)
        return this
    }
    ret = this.expr.compile(ctx)
    
    if (ret == null){
        this.check(false,"del refexpr error")
    }else if (type(ret) == type(VarExpr) {
        var = ret
        
        if !var.structtype{
            internal.get_object_value(); return ret
        }
        
        if !var.pointer{
            panic("var must be pointer " + this.expr.toString())
        }
        if var.size != 1 && var.size != 2 && var.size != 4 && var.size != 8{
            parse_err("type must be [i8 - u64]:%s\n",this.expr.toString())
        }
        
        compile.Load(var.size,var.isunsigned)
        return ret
    }else if type(ret) == type(ast.StructMemberExpr) {
        sm = ret
        Member* m = sm.ret
        if m == null{
            parse_err("del ref can't find the class member:%s\n",this.expr.toString())
        }
        if type(expr) != type(ast.DelRefExpr) {
            
            compile.Load(m)
        }
        compile.Load(m.size,m.isunsigned)
        return ret
    
    }else if type(ret) == type(ChainExpr) {
        ce = ret
        
        if ce.ret{
            Member* m = ce.ret
            compile.Load(m)

            return ret
        }
    }
    parse_err("only support del ref for expression :%s\n",this.expr.toString())
}

AddrExpr::compile(ctx){
    record()
    
    if expr != null && type(expr) == type(ChainExpr) {
        ce = expr
        if !ce.ismem(ctx){
            parse_err("only support & struct.menber %s\n",expr.toString())
        }
        ce.compile(ctx)
        
        return ce
    }
    if package != ""{
        
        var = Context::getVar(ctx,this.package)
        if var != null && var.structtype{
            
            StructMemberExpr sm(package,line,column)
            sm.member = varname
            sm.var    = var
            Member* m = sm.getMember()
            if m != null{
                
                compile.GenAddr(var)
                
                compile.Load()
                
                compile.writeln("	add $%d, %%rax", m.offset)
                
                if m.bitfield{
                    parse_err(
                        "AsmError: adress to bitfield error! "
                        "line:%d column:%d \n\n"
                        "expression:\n%s\n",
                        this.line,this.column,this.toString())
                }
                return this
            }
        }
        
        parse_err("not support &p.globalvar\n")
    }
    var = Context::getVar(ctx,this.varname)
    if var == null
        parse_err("AddExpr: var:%s not exist\n",varname)
    realVar = var.getVar(ctx)
    compile.GenAddr(realVar)

    return this
}