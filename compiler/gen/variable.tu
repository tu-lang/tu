use parser.package
use ast
use std
use compile
use utils
use fmt

class VarExpr : ast.Ast {
    varname = varname
    offset
    name
    is_local    = true
    is_variadic = false
    //FIXME: conflict with import package
    package     = ""
    ivalue      = ""
    
    structname  = ""
    structtype  = false
    structpkg  
    pointer     = false
    
    type
    size    
    isunsigned  = false

    stack       = false
    stacksize   = 0
    elements    = []
    sinit       
    
    ret 
    funcpkg  = ""
    funcname = ""

    tyassert
    func init(varname,line,column){
        super.init(line,column)
    }
}
VarExpr::toString() { return fmt.sprintf("VarExpr(%.%s)",this.package,this.varname) }
VarExpr::isMemtype(ctx){
    v = this.getVar(ctx)
    if v != null && v.structtype {
        acualPkg = compile.currentParser.import[v.structpkg]
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
    // package = this.package
    if this.package != "" {
        if GP().getGlobalVar(this.package,this.varname) != null {
            this.ret = GP().getGlobalVar(this.package,this.varname)
            if this.ret.structtype
                return ast.Var_Global_Extern_Static
            return ast.Var_Global_Extern
        }
    }
    if GP().getGlobalVar("",this.package) != null {
        this.ret = GP().getGlobalVar("",this.package)
        if (this.ret.structtype)
            return ast.Var_Global_Local_Static_Field
        else return ast.Var_Obj_Member
    }
    if GP().getGlobalVar("",this.varname) != null {
        this.ret = GP().getGlobalVar("",this.varname)
        if this.ret.structtype
            return ast.Var_Local_Static
        return ast.Var_Global_Local
    }
    this.ret = ast.getVar(ctx,this.package)
    if(this.ret != null){
        if this.ret.structtype
            return ast.Var_Local_Static_Field
        return ast.Var_Obj_Member
    } 

    if this.package == "" {
        this.ret = ast.getVar(ctx,this.varname)
        if this.ret != null {
            if this.ret.structtype
                return ast.Var_Local_Static
            return ast.Var_Local
        }
    }
    fn = GP().getGlobalFunc(this.package,this.varname,false)
    if fn {
        this.ret = this
        this.type = ast.U64

        funcname = fn.name
        this.funcpkg = fn.package.getFullName()
        return ast.Var_Func
    }   
    this.check(false,
        fmt.sprintf("get var type use of undefined variable %s.%s at line %d co %d filename:%s\n",
            this.package,this.varname,
            this.line,this.column,
            GP().filepath
        )
    )
}
VarExpr::compile(ctx){
    utils.debugf("gen.VarExpr::compile() package :%s varname:%s \n",this.package,this.varname)
    this.record()
    match this.getVarType(ctx)
    {
        ast.Var_Obj_Member : { 
            compile.GenAddr(this.ret)
            compile.Load()
            compile.Push()
            
            internal.object_member_get(this,this.varname)
        }
        ast.Var_Global_Local_Static_Field : {
            sm = new StructMemberExpr(this.package,this.line,this.column)
            sm.member = this.varname
            sm.var    = this.ret
            sm.compile(ctx)
            return sm
        }
        ast.Var_Global_Extern_Static | ast.Var_Local | ast.Var_Global_Local | ast.Var_Global_Extern | ast.Var_Local_Static : 
        { 
            compile.GenAddr(this.ret)
            //UNSAFE: dyn & native in same expression is unsafe      
            if !this.ret.stack {
                if this.ret.structtype == True && 
                this.ret.pointer == False   && 
                this.ret.type <= ast.U64 && 
                this.ret.type >= ast.I8    
                    compile.LoadSize(this.ret.size,this.ret.isunsigned)
                else                                    
                    compile.Load()
            }
        }
        ast.Var_Func : {  
            fn = this.funcpkg + "_" + this.funcname
            utils.debug("found function pointer:%s",fn)
            compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", fn)
        }
        _ : this.check(false,"unkonwn var type")
    }
    return this.ret
}
VarExpr::assign(ctx , opt , rhs){
    utils.debugf("gen.VarExpr::assign() package :%s varname:%s \n",this.package,this.varname)
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
        ast.Var_Global_Local_Static_Field:{
            sm = new StructMemberExpr(this.package,this.line,this.column)
            sm.member = this.varname
            sm.var    = this.ret

            oh = new OperatorHelper(ctx,sm,rhs,opt)
            oh.var = this.ret
            return oh.gen()
        }
        ast.Var_Global_Extern_Static | ast.Var_Global_Extern | ast.Var_Global_Local | ast.Var_Local | ast.Var_Local_Static :{ 
            if this.ret.stack && type(rhs) == type(ArrayExpr) {
                return this.stack_assign(ctx,opt,rhs)
            }
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
        _ : this.check(false,"unkown var type")
    }
    return null
}
VarExpr::clone(){
    nvar = new VarExpr(this.varname,this.line,this.column)

    nvar.varname = this.varname
    nvar.offset = this.offset
    nvar.name   = this.name
    nvar.is_local = this.is_local
    nvar.is_variadic = this.is_variadic
    nvar.package  = this.package
    nvar.ivalue = this.ivalue
    nvar.structname = this.structname
    nvar.structtype = this.structtype
    nvar.structpkg = this.structpkg
    nvar.pointer = this.pointer
    nvar.type = this.type
    nvar.size = this.size
    nvar.isunsigned = this.isunsigned
    nvar.stack = this.stack
    nvar.stacksize = this.stacksize
    nvar.elements  = this.elements
    nvar.tyassert = this.tyassert
    nvar.ret = this.ret
    nvar.funcpkg = this.funcpkg
    nvar.funcname = this.funcname
    return nvar
}

VarExpr::getStackSize(p){
    utils.debug("gen.VarExpr.getStackSize()")
    if this.stack {
        if this.structname != ""  {
            this.check(this.stacksize != 0)
            acualPkg = p.import[this.structpkg]
            s = package.getStruct(acualPkg,this.structname)
            if(s == null) {
                fmt.println(this.structname)
                this.check(false,
                    fmt.sprintf("static var not exist pkg:%s,name:%s",acualPkg,this.structname)
                )
            }
            if(s.size == 0) {
                this.check(false,"static var size is 0")
            }
            return s.size * this.stacksize
        }
        if this.stacksize == 0 || this.size == 0 
            this.panic("stack size can't be 0")
        return this.size * this.stacksize
    //BUG: fixme  dyn & static
    }else if this.structtype && !this.pointer && this.type <= ast.U64 && this.type >= ast.I8 {
        if this.size == 0  this.panic("var size is 0,something wrong")
        return this.size
    }else{
        return 8
    }
}

VarExpr::stack_assign(ctx , opt , rhs){
    utils.debugf("gen.VarExpr::stack_assign() package :%s varname:%s \n",this.package,this.varname)
    var = this.ret
    if !var.stack this.check(false,"should be stack var in stack_assign expression")

    if type(rhs) != type(ArrayExpr) rhs.check(false,"only support array expr in stack assign expression")
    arr = rhs.lit
    if var.stacksize != std.len(arr) var.check(false,"stack size != element size in stack_assign")
    mt = "mov"
    ts = 1
    match var.type {
        ast.I8 | ast.U8: {
            mt = "movb" ts = 1
        }
        ast.I16 | ast.U16 : {
            mt = "movw" ts = 2
        }
        ast.I32 | ast.U32 : {
            mt = "movl" ts = 4
        }
        ast.I64 | ast.U64 : {
            mt = "movq" ts = 8
        }
        _ : this.check(false,"should be i8 .. u64 type in stack assign") 
    }
    compile.GenAddr(var)
    index = 0
    for i : arr {
        if type(i) != type(IntExpr) {
            i.check(false,"should be intexpr in stack assign")
        }
        ie = i
        compile.writeln("\t%s	$%s , %d(%%rax)",mt, ie.lit,index * ts )
		index += 1
    }
	return null

}