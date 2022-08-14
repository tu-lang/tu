use ast
use compile
use fmt
use utils

ast.AssignExpr::compile(ctx){
    record()

    utils.debug("AssignExpr: parsing... lhs:%s opt:%s rhs:%s",
          lhs.toString(),
          getTokenString(opt),
          rhs.toString()
    )
    if !this.rhs    panic("AsmError: right expression is wrong expression:" + this.toString())
    
    f = compile.currentFunc
    if type(lhs) == type(ast.VarExpr) {
        varExpr = lhs
        package = compile.currentFunc.parser.getpkgname() 
        varname = varExpr.varname

        if !varExpr.is_local {

            package = varExpr.package
            if (var = ast.getVar(ctx,package) != null) {
                
                compile.GenAddr(var)
                compile.Load()
                compile.Push()

                this.rhs.compile(ctx)
                compile.Push()
                
                internal.call_object_operator(this.opt,varname,"runtime_object_unary_operator")
                return null
            }
            
            cpkg = compile.currentFunc.parser.getpkgname()
            full_package = ""
            if std.exist(package,compile.currentFunc.parser.import)
                full_package = compile.currentFunc.parser.import

            if std.exist(full_package.packages,package){
                varExpr = package.packages[full_package].getGlobalVar(varname)
            }else if std.len(package.packages,cpkg) {
                varExpr = package.packages[cpkg].getGlobalVar(package)
                sm = new ast.StructMemberExpr(package,this.line,this.column)
                sm.member = varname
                sm.var    = varExpr
                this.lhs = sm
                
            }
            
            if !varExpr 
                panic("AsmError: assignexpr use of undefined global variable %s at line %d co %d\n",
                    varname,this.line,this.column
                )
        
        }else if package.packages[package].getGlobalVar(varname){
            varExpr = package.packages[package].getGlobalVar(varname)
        }else if std.exist(varExpr.varname,f.params_var){
            
            varExpr = f.params_var[varExpr.varname]
            std.tail(ctx).createVar(varExpr.varname,varExpr)
        }else{
            varExpr = f.locals[varExpr.varname]
            std.tail(ctx).createVar(varExpr.varname,varExpr)
        }
        
        if varExpr.isMemtype(ctx){
            oh = new OperatorHelper(ctx,lhs,rhs,this.opt)
            oh.var = varExpr
            return oh.gen()
        }

        compile.GenAddr(varExpr)
        compile.Push()

        this.rhs.compile(ctx)
        compile.Push()
        
        internal.call_operator(this.opt,"runtime_unary_operator")
        return null

    }else if type(lhs) == type(ast.IndexExpr) 
    {
        index    = lhs 
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
                if !varExpr panic("AsmError:use of undefined global variable %s",varname)
            }
        }else if package.packages[package].getGlobalVar(varname){
            varExpr = package.packages[package].getGlobalVar(varname)
        }else if std.exist(varname,f.params_var){
            
            varExpr = f.params_var[varname]
        }else{
            varExpr = f.locals[varname]
        }
        if !varExpr
            panic("SyntaxError: not find variable %s at line:%d, column:%d file:%s\n", varname,line,column,compile.currentFunc.parser.filepath)

        std.tail(ctx).createVar(varExpr.varname,varExpr)
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
        oh = new OperatorHelpe(ctx,lhs,rhs,this.opt)
        return oh.gen()
    }else if type(lhs) == type(ast.DelRefExpr) {
        oh = OperatorHelper(ctx,lhs,rhs,this.opt)
        return oh.gen()
    }else if type(lhs) == type(ast.ChainExpr) {
        ce = lhs
        if ce.ismem(ctx) {
            oh. OperatorHelper(ctx,lhs,rhs,this.opt)
            return oh.gen()
        }
    }
    panic("SyntaxError: can not assign to " + string(type(lhs).name()))
}

ast.BinaryExpr::isMemtype(ctx)
{    
    mhandle = false
    var = null
    this.check(this.lhs != null)
    
    if type(this.lhs) == type(ast.StructMemberExpr) ||  (this.rhs && type(this.rhs) == type(ast.StructMemberExpr) )
        mhandle = true
    
    if type(this.lhs) == type(ast.DelRefExpr) || (this.rhs && type(this.rhs) == type(ast.DelRefExpr) )
        mhandle = true
    
    if type(this.lhs) == type(ast.VarExpr) {
        var = this.lhs
        var = var.getVar(ctx)
        if var.structtype
            mhandle = true
    }
    if this.rhs && type(this.rhs) == type(ast.VarExpr) {
        var = this.rhs
        var = var.getVar(ctx)
        if var.structtype
            mhandle = true
    }
    if type(this.lhs) == type(BinaryExpr) {
        b = this.lhs
        if b.isMemtype(ctx) return true
    }
    if this.rhs && type(this.rhs) == type(BinaryExpr) {
        b = this.rhs
        if b.isMemtype(ctx) return true
    }
    if type(this.lhs) == type(ast.ChainExpr) {
        ce = this.lhs
        if ce.ismem(ctx)
            return true
    }
    if this.rhs && type(this.rhs) == type(ast.ChainExpr) {
        ce = this.rhs
        if ce.ismem(ctx)
            return true
    }
    return mhandle
}

ast.BinaryExpr::compile(ctx)
{
    record()

    utils.debug("BinaryExpr: parsing... lhs:%s opt:%s rhs:%s",
          lhs.toString(),
          getTokenString(opt),
          rhs.toString()
    )
    if !this.rhs && (this.opt != BITNOT && this.opt != LOGNOT)
        panic("AsmError: right expression is wrong expression:" + this.toString())
    
    if isMemtype(ctx){
        oh new OperatorHelper(ctx,lhs,rhs,this.opt)
        return oh.gen()
    }
    if opt == ast.LOGOR || opt == ast.LOGAND 
        return this.FirstCompile(ctx)
    
    this.lhs.compile(ctx)
    compile.Push()

    
    if this.rhs   this.rhs.compile(ctx)
    else            compile.writeln("   mov $0,%%rax")
    compile.Push()

    
    internal.call_operator(this.opt,"runtime_binary_operator")
    return null
}
ast.DelRefExpr::compile(ctx){
    record()
    
    if type(this.expr) == type(ast.StringExpr) {
        se = this.expr
        compile.writeln("    lea %s(%%rip), %%rax", se.name)
        return this
    }
    ret = this.expr.compile(ctx)
    
    if (ret == null){
        this.check(false,"del refexpr error")
    }else if type(ret) == type(ast.VarExpr) {
        var = ret
        
        if !var.structtype {
            internal.get_object_value() return ret
        }
        
        if !var.pointer {
            panic("var must be pointer " + this.expr.toString())
        }
        if var.size != 1 && var.size != 2 && var.size != 4 && var.size != 8{
            parse_err("type must be [i8 - u64]:%s\n",this.expr.toString())
        }
        
        compile.Load(var.size,var.isunsigned)
        return ret
    }else if type(ret) == type(ast.StructMemberExpr) {
        sm = ret
        m = sm.ret
        if m == null{
            parse_err("del ref can't find the class member:%s\n",this.expr.toString())
        }
        if type(expr) != type(ast.DelRefExpr) {
            
            compile.Load(m)
        }
        compile.Load(m.size,m.isunsigned)
        return ret
    
    }else if type(ret) == type(ast.ChainExpr) {
        ce = ret
        
        if ce.ret {
            m = ce.ret
            compile.Load(m)

            return ret
        }
    }
    parse_err("only support del ref for expression :%s\n",this.expr.toString())
}

ast.AddrExpr::compile(ctx){
    record()
    
    if expr != null && type(expr) == type(ast.ChainExpr) {
        ce = expr
        if !ce.ismem(ctx){
            parse_err("only support & struct.menber %s\n",expr.toString())
        }
        ce.compile(ctx)
        
        return ce
    }
    if package != ""{
        
        var = ast.getVar(ctx,this.package)
        if var != null && var.structtype{
            
            StructMemberExpr sm(package,line,column)
            sm.member = varname
            sm.var    = var
            m = sm.getMember()
            if m != null{
                
                compile.GenAddr(var)
                
                compile.Load()
                
                compile.writeln("	add $%d, %%rax", m.offset)
                
                if m.bitfield {
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
    var = ast.getVar(ctx,this.varname)
    if var == null
        panic("AddExpr: var:%s not exist\n",varname)
    realVar = var.getVar(ctx)
    compile.GenAddr(realVar)

    return this
}
BinaryExpr::FirstCompile(ctx){
    record()
    c = compile.incr_labelid()
    this.lhs.compile(ctx)
    match opt {
        ast.LOGAND:{
            if !condIsMtype(this.lhs,ctx)
                internal.isTrue()
            compile.writeln("    cmp $0, %%rax")
			compile.writeln("	je .L.false.%d", c) 
        }
        ast.LOGOR: {
            if  !condIsMtype(this.lhs,ctx)
                internal.isTrue()
            compile.writeln("    cmp $1, %%rax")
			compile.writeln("	je .L.true.%d", c) 
        }
    }
    this.rhs.compile(ctx)
    match opt {
        ast.LOGAND: {
            if  !condIsMtype(this.rhs,ctx)
                internal.isTrue()
            compile.writeln("	cmp $0,%%rax")    
            compile.writeln("	je .L.false.%d", c)
            compile.writeln("	jmp .L.true.%d", c)
        }
        ast.LOGOR:{
            if  !condIsMtype(this.rhs,ctx)
                internal.isTrue()
            compile.writeln("	cmp $1,%%rax")    
            compile.writeln("	je .L.true.%d", c)
            compile.writeln("	jmp .L.false.%d", c)
        }
    }

    compile.writeln(".L.false.%d:", c)
    compile.writeln("	mov $0, %%rax")
    compile.writeln("	jmp .L.end.%d", c)
    compile.writeln(".L.true.%d:", c) 
    compile.writeln("	mov $1, %%rax")
    compile.writeln(".L.end.%d:", c)
    return null
}