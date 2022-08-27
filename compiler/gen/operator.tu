use ast
use compile
use fmt
use utils

class DelRefExpr  : ast.Ast { 
    expr 
    func init(line,column){
        super.init(line,column)
    }
    func toString(){
        return "DelRefExpr(" + expr.toString() + ")"
    }
}
class AddrExpr   : ast.Ast {
    package
    varname
    expr
    func init(line,column){super.init(line,column)}
    func toString(){
        return "AddrExpr(&(" + package + ")." + varname + ")"
    }
}
class AssignExpr : ast.Ast {
    opt
    lhs rhs
    func init(line,column){
        super.init(line,column)
    }
}
AssignExpr::toString() {
    str = "AssignExpr(lhs="
    if lhs
        str += lhs.toString()
    str += ",rhs="
    if rhs
        str += rhs.toString()
    str += ")"
    return str
}
AssignExpr::compile(ctx){
    this.record()

    utils.debug("AssignExpr: parsing... lhs:%s opt:%s rhs:%s",
          lhs.toString(),
          getTokenString(opt),
          rhs.toString()
    )
    if !this.rhs    this.panic("AsmError: right expression is wrong expression:" + this.toString())
    
    f = compile.currentFunc
    match type(lhs) {
        type(VarExpr) : {
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
                    sm = new StructMemberExpr(package,this.line,this.column)
                    sm.member = varname
                    sm.var    = varExpr
                    this.lhs = sm
                    
                }
            
                if !varExpr 
                    this.panic("AsmError: assignexpr use of undefined global variable %s at line %d co %d\n",
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
        }
        type(IndexExpr) : {
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
                    if !varExpr this.panic("AsmError:use of undefined global variable %s",varname)
                }
            }else if package.packages[package].getGlobalVar(varname){
                varExpr = package.packages[package].getGlobalVar(varname)
            }else if std.exist(varname,f.params_var){
                
                varExpr = f.params_var[varname]
            }else{
                varExpr = f.locals[varname]
            }
            if !varExpr
                this.panic("SyntaxError: not find variable %s at line:%d, column:%d file:%s\n", varname,line,column,compile.currentFunc.parser.filepath)

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
        }
        type(StructMemberExpr) : {
            oh = new OperatorHelpe(ctx,lhs,rhs,this.opt)
            return oh.gen()
        }
        type(DelRefExpr) : {
            oh = OperatorHelper(ctx,lhs,rhs,this.opt)
            return oh.gen()
        }
        type(ChainExpr) : {
            ce = lhs
            if ce.ismem(ctx) {
                oh. OperatorHelper(ctx,lhs,rhs,this.opt)
                return oh.gen()
            }
            return ce.assign(ctx,this.opt,this.rhs)
        }
    }
    this.panic("SyntaxError: can not assign to " + string(type(lhs).name()))
}
DelRefExpr::compile(ctx){
    this.record()
    
    if type(this.expr) == type(StringExpr) {
        se = this.expr
        compile.writeln("    lea %s(%%rip), %%rax", se.name)
        return this
    }
    ret = this.expr.compile(ctx)
    
    if (ret == null){
        this.check(false,"del refexpr error")
    }else if type(ret) == type(VarExpr) {
        var = ret
        
        if !var.structtype {
            internal.get_object_value() return ret
        }
        
        if !var.pointer {
            this.panic("var must be pointer " + this.expr.toString())
        }
        if var.size != 1 && var.size != 2 && var.size != 4 && var.size != 8{
            parse_err("type must be [i8 - u64]:%s\n",this.expr.toString())
        }
        
        compile.LoadSize(var.size,var.isunsigned)
        return ret
    }else if type(ret) == type(StructMemberExpr) {
        sm = ret
        m = sm.ret
        if m == null{
            parse_err("del ref can't find the class member:%s\n",this.expr.toString())
        }
        if type(expr) != type(DelRefExpr) {
            
            compile.LoadMember(m)
        }
        compile.LoadSize(m.size,m.isunsigned)
        return ret
    
    }else if type(ret) == type(ChainExpr) {
        ce = ret
        
        if ce.ret {
            m = ce.ret
            compile.LoadMember(m)

            return ret
        }
    }
    parse_err("only support del ref for expression :%s\n",this.expr.toString())
}

AddrExpr::compile(ctx){
    this.record()
    
    if expr != null && type(expr) == type(ChainExpr) {
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
        this.panic("AddExpr: var:%s not exist\n",varname)
    realVar = var.getVar(ctx)
    compile.GenAddr(realVar)

    return this
}
class BinaryExpr : ast.Ast {
    opt
    lhs rhs
    func init(line,column){
        super.init(line,column)
    }
}
BinaryExpr::isMemtype(ctx)
{    
    this.check(this.lhs != Null)

    if this.lhs != null && exprIsMtype(this.lhs,ctx) return True
    if this.rhs != null && exprIsMtype(this.lhs,ctx) return True
    return False
}

BinaryExpr::compile(ctx)
{
    this.record()

    utils.debug("BinaryExpr: parsing... lhs:%s opt:%s rhs:%s",
          lhs.toString(),
          getTokenString(opt),
          rhs.toString()
    )
    if !this.rhs && (this.opt != BITNOT && this.opt != LOGNOT)
        this.panic("AsmError: right expression is wrong expression:" + this.toString())
    
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

BinaryExpr::FirstCompile(ctx){
    this.record()
    c = compile.incr_labelid()
    this.lhs.compile(ctx)
    internal.isTrue()
    match opt {
        ast.LOGAND:{
            compile.writeln("    cmp $0, %%rax")
			compile.writeln("	je .L.false.%d", c) 
        }
        ast.LOGOR: {
            compile.writeln("    cmp $1, %%rax")
			compile.writeln("	je .L.true.%d", c) 
        }
    }
    this.rhs.compile(ctx)
    internal.isTrue()
    match opt {
        ast.LOGAND: {
            compile.writeln("	cmp $0,%%rax")    
            compile.writeln("	je .L.false.%d", c)
            compile.writeln("	jmp .L.true.%d", c)
        }
        ast.LOGOR:{
            compile.writeln("	cmp $1,%%rax")    
            compile.writeln("	je .L.true.%d", c)
            compile.writeln("	jmp .L.false.%d", c)
        }
    }

    compile.writeln(".L.false.%d:", c)
    internal.gen_false()
    compile.writeln("	jmp .L.end.%d", c)
    compile.writeln(".L.true.%d:", c) 
    internal.gen_true()
    compile.writeln(".L.end.%d:", c)
    return null
}


BinaryExpr::toString() {
    str = "BinaryExpr("
    str += "opt=" + ast.getTokenString(this.opt)
    if lhs {
        str += ",lhs="
        str += lhs.toString()
    }
    if rhs {
        str += ",rhs="
        str += rhs.toString()
    }
    str += ")"
    return str
}
