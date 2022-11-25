use utils
use ast
use internal
use compile
use parser
use parser.package
use string
 
IndexExpr::compileStaticIndex(ctx,size){

	if this.index == null this.check(false,"static var index is null")
	if type(this.index) == type(IntExpr) {
		i = this.index
		num = string.tonumber(i.literal)
		num *= size
		compile.writeln("\tmov $%d,%%rdi",num)
		return null
	}
	if(type(this.index) == type(VarExpr)){
		var = this.index
		var = var.getVar(ctx)
		if var.pointer this.check(false,"index can't be pointer")
		if !var.structtype  this.check(false,"index must be statictype")
		if var.type < I8 || var.type > U64 this.check("index must be 1 - 8 bytes type")
		var.compile(ctx)
	}else if type(this.index) == type(BinaryExpr) {
		b = this.index
		if !b.isMemtype(ctx) this.panic("must be mem binary operator for array index")
		b.compile(ctx)
	}else if type(this.index) == type(StructMemberExpr) {
		sm = this.index
		sm.compile(ctx)
		compile.LoadMember(sm.ret)
	}else if type(this.index) == type(MemberExpr) {
		me = this.index
		if !me.ismem(ctx) this.panic("memexpr should be mem type in index expr")
		se = me.compile(ctx)
		compile.LoadMember(se.ret)
	}else if type(this.index) == type(FunCallExpr) {
        this.index.compile(ctx)
    }else{
		this.check(false,"index must be var in arry index")
	}
	if size != 1{
		compile.writeln("\timul $%d , %%rax",size)
	}
	compile.writeln("\tmov %%rax , %%rdi")

}
 IndexExpr::compile_chain_static(ctx,ty){
	 compile.Push() 
	 this.compileStaticIndex(ctx,parser.typesize[int(ty)])
	 compile.writeln("\tadd %%rdi , (%%rsp)") //加上offset
	 compile.Pop("%rax")
	 return null
 }
 IndexExpr::compile_static( ctx){
	 f = compile.currentFunc   
	 var = new VarExpr(this.varname,this.line,this.column)
	 var.package = this.package
	 match var.getVarType(ctx) {
		ast.Var_Global_Extern_Static | ast.Var_Local_Static: { 
			
			 if !var.ret.pointer && !var.ret.stack this.check(false,"must be pointer type in array index")
			 compile.GenAddr(var.ret)
			 if !var.ret.stack
			 	compile.Load()
			 compile.Push()
			 this.compileStaticIndex(ctx,var.ret.size)
			 compile.writeln("\tadd %%rdi , (%%rsp)") //加上offset
			 compile.Pop("%rax")
			 compile.LoadSize(var.ret.size,var.ret.isunsigned)
		 }
		 ast.Var_Global_Local_Static_Field | ast.Var_Local_Static_Field:{ 
			 sm = new StructMemberExpr(var.package,this.line,this.column)
			 sm.member = var.varname
			 sm.var    = var.ret
			 sm.compile(ctx)
			 me = sm.ret
			 if me.pointer && !me.arr
				 compile.LoadMember(me)
			 compile.Push() 
			 if !me.pointer && !me.isarr this.check(false,"must be pointer member or arr")
 
			 this.compileStaticIndex(ctx,me.size)
			 compile.writeln("\tadd %%rdi , (%%rsp)") //加上offset
			 compile.Pop("%rax")
			 ss = me.size
			 if (me.size > 8){
				 if(me.structname == "" || me.pointer) {
					 this.check(false,"only struct arr can size > 8")
				 }
				 this.ret = me
				 break
			 }
			 compile.LoadSize(ss,me.isunsigned)
			 this.ret = me
		 }
		 _ : this.check(false,"array_static inex: unuspport dynamic var")
	 }
	 return null
 }
 IndexExpr::assign_static( ctx , opt , rhs){
	 f = compile.currentFunc   
	 var = new VarExpr(this.varname,this.line,this.column)
	 var.package = this.package
	 match var.getVarType(ctx) {
		 ast.Var_Global_Extern_Static |  ast.Var_Local_Static: { 

			 if !var.ret.pointer && !var.ret.stack this.check(false,"must be pointer type in array index")
			 compile.GenAddr(var.ret)
			 if !var.ret.stack
			 	compile.Load()
			 compile.Push()
			 this.compileStaticIndex(ctx,var.ret.size)
			 compile.writeln("\tadd %%rdi , (%%rsp)") //加上offset
			 if(opt == ast.ASSIGN){
				oh = new OperatorHelper(ctx,null,null,ast.ASSIGN)
			    oh.genRight(false,rhs)
			    compile.Cast(rhs.getType(ctx),var.ret.type)
			    compile.Store(var.ret.size)
                break
            }
            compile.writeln("\tmov (%%rsp) , %%rax")
			compile.LoadSize(var.ret.size,var.ret.isunsigned)
            compile.Push()

			 oh = new OperatorHelper(ctx,this,rhs,ast.ASSIGN)
			 oh.initcond(true,var.ret.size,var.ret.type,var.ret.pointer)
			 oh.genRight(false,rhs)
			 oh.assign()
		 }
		 ast.Var_Global_Local_Static_Field | ast.Var_Local_Static_Field:{ 
			 sm = new StructMemberExpr(var.package,this.line,this.column)
			 sm.member = var.varname
			 sm.var    = var.ret
			 sm.compile(ctx) 
			 me = sm.ret
			 if me.pointer && !me.isarr
				 compile.LoadMember(me)
			 compile.Push() 
			 if !me.pointer && !me.isarr this.check(false,"must be pointer member")
 
			 this.compileStaticIndex(ctx,me.size)
			 compile.writeln("\tadd %%rdi , (%%rsp)") //加上offset
			 if(opt == ast.ASSIGN){
				oh = new OperatorHelper(ctx,null,null,ast.ASSIGN)
                oh.genRight(false,rhs)
                compile.Cast(rhs.getType(ctx),me.type)
                compile.Store(me.size)
                return sm
            }
            compile.writeln("\tmov (%%rsp) , %%rax")
			compile.LoadSize(me.size,me.isunsigned)
            compile.Push()

			 oh = new OperatorHelper(ctx,this,rhs,ast.ASSIGN)
			 oh.initcond(true,me.size,me.type,me.pointer)

			 oh.genRight(false,rhs)
			 oh.assign()
			 return sm
		 }
		 _ : this.check(false,"array_static inex: unuspport dynamic var")
	 }
	 return null
 }
 