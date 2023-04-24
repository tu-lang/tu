
use ast 
use compile
use internal
use parser
use parser.package
use std
use utils


FunCallExpr::call(ctx,fc)
{
	if !fc.isObj && fc.block == null {
		compile.writeln("#    register %s",compile.currentFunc.fullname())
		return this.registercall(ctx,fc)
	}
	return this.stackcall(ctx,fc)
}
FunCallExpr::stackcall(ctx,fc)
{
	args = this.args
	callname = this.funcname
	cfunc = compile.currentFunc

	if std.len(fc.params_order_var) != std.len(this.args) 
		utils.debug("ArgumentError: expects %d arguments but got %d\n",std.len(fc.params_order_var),std.len(this.args))

	stack_args = this.PushStackArgs(ctx,fc)
	if !fc.isObj {
		if !fc.isExtern {
			callname = fc.fullname()
		}
		compile.writeln("    call %s",callname)
	}else{
		//push funcaddr,argn,argn-1,arg....,arg1
		compile.writeln("    mov %d(%%rsp),%%r10",stack_args * 8)
		compile.writeln("    mov $0, %%rax")
		compile.writeln("    call *%%r10")
	}
	compile.writeln("    add $%d, %%rsp", stack_args * 8)
	return null
}
FunCallExpr::PushStackArgs(prevCtxChain,fc)
{
	stack = 0
	hashvariadic = this.hasVariadic()
	if std.len(fc.params_order_var) > std.len(this.args) {
		miss = std.len(fc.params_order_var) - std.len(this.args)
		compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
		for i  = 0 ; i < miss ; i += 1 {
			stack += 1
			if fc.params_order_var[std.len(fc.params_order_var) - 1 - i].structtype {
				compile.writeln("    push $0")
			}else{
				compile.Push()
			}
		}
	}
	staticcount = std.len(fc.params_order_var) - 1
	for  i = std.len(this.args) - 1; i >= 0; i -= 1 {
		arg = this.args[i]
		ret = arg.compile(prevCtxChain)
		if ret != null && type(ret) == type(gen.StructMemberExpr) {
			sm = ret
			compile.LoadMember(sm.getMember())
		}else if ret != null && type(ret) == type(gen.ChainExpr) {
			ce = ret
			if type(ce.last) == type(gen.MemberCallExpr) {
			}
			else if type(arg) != type(gen.AddrExpr) {
				compile.LoadMember(ce.ret)
			}
		}
		compile.Push()
		stack += 1
		//func(a,b,c,args...)
		//call(1,2,3,4)
		if !hashvariadic && fc.is_variadic && std.len(this.args) >= std.len(fc.params_order_var) && i == staticcount {
			compile.writeln("    push $%d",std.len(this.args) - staticcount)
			compile.writeln("    push %%rsp")
			stack += 2
		}
	}
	return stack
}

FunCallExpr::registercall(ctx,fc)
{
	args = this.args
	funcname = this.funcname
	gp = 0
	fp = 0
	have_variadic = false
	cfunc = compile.currentFunc
	for arg : args {
		if arg == null {
			this.check(false,"arg is null")
		}
		if  type(arg) == type(gen.VarExpr) && cfunc {
			var = arg
			if cfunc.params_var[var.varname] != null  {
				var2 = cfunc.params_var[var.varname]
				if var2 && var2.is_variadic
					have_variadic = true
			}
		}
	}
	if std.len(fc.params) != std.len(this.args)
		utils.debug("ArgumentError: expects %d arguments but got %d\n",std.len(fc.params),std.len(this.args))

	stack_args = this.PushRegisterArgs(ctx,fc)

	if !cfunc || !cfunc.is_variadic || !have_variadic
		for (i = 0; i < compile.GP_MAX; i+=1) {
			compile.Pop(compile.args64[gp])
			gp += 1
		}
	if !fc.isObj {
		if fc.isExtern {
			compile.writeln("    lea %s(%%rip), %%rax", funcname)
		}else{
			realfuncname = fc.fullname()
			compile.writeln("    lea %s(%%rip), %%rax", realfuncname)
		}

		compile.writeln("    mov %%rax, %%r10")
		compile.writeln("    mov $%d, %%rax", fp)
		compile.writeln("    call *%%r10")
	}else{
		if std.len(args) > 6 {
			compile.writeln("   mov %d(%%rsp),%%r10",(std.len(args) - 6) * 8)
		}else{
			compile.Pop("%%r10")
		}
		compile.writeln("    mov $%d, %%rax", fp)
		compile.writeln("    call *%%r10")
	}

	if compile.currentFunc && compile.currentFunc.is_variadic && have_variadic {
		c = ast.incr_labelid()
		compile.Push()
		compile.writeln("    push -8(%%rbp)")
		internal.call("runtime_get_object_value",1)
		compile.writeln("    mov %%rax,%d(%%rbp)",compile.currentFunc.stack)
		compile.Pop("%rax") 

		if(this.is_delref){
			compile.writeln("    add $-6,%d(%%rbp)",compile.currentFunc.stack)
		}else{
			compile.writeln("    add $-5,%d(%%rbp)",compile.currentFunc.stack)
		}
		compile.writeln("    cmp $0,%d(%%rbp)",compile.currentFunc.stack)
		compile.writeln("    jle L.if.end.%d",c)
		// compile.writeln("    cmp %d(%%rbp),%%rdi",compile.currentFunc.stack)
		// compile.writeln("    add $%d, %%rsp", stack_args * 8)
		compile.writeln("    mov %d(%%rbp),%%rdi",compile.currentFunc.stack)
		compile.writeln("    imul $8,%%rdi")
		compile.writeln("    add %%rdi, %%rsp")
		compile.writeln("L.if.end.%d:",c)
	}else{
		compile.writeln("    add $%d, %%rsp", stack_args * 8)
	}
	return null
}

FunCallExpr::hasVariadic(){
	for(arg : this.args){
		if (type(arg) == type(gen.VarExpr) && compile.currentFunc){
			var = arg
			if( compile.currentFunc.params_var[var.varname] != null ){
				var2 = compile.currentFunc.params_var[var.varname]
				if(var2 && var2.is_variadic){
					return true
				}
			}
		}
	}
	return false
}
FunCallExpr::PushRegisterArgs(ctx,fc){
    utils.debug("compile.Push_arg()")
    stack = 0 gp = 0
	current_call_have_im = this.hasVariadic()
	currentFunc = compile.currentFunc

    if currentFunc && currentFunc.is_variadic && current_call_have_im
    {
        c = ast.incr_labelid()
        stack_offset = 0
        if this.is_delref {
            params = -16
            for (i = 0; i < 5; i += 1) {
                compile.writeln("    mov %d(%%rbp),%%rax",params)
                internal.get_object_value()
                compile.writeln("    mov %%rax,%s",compile.args64[i])
                params += -8
            }
            compile.writeln("    mov 16(%%rbp),%%rax")
            if( this.is_delref )
                internal.get_object_value()
            compile.writeln("    mov %%rax,%%r9")

            stack_offset = 16
        }else
        {
            stack_offset = 8
            params = -8
            for (i = 0; i < 6; i += 1) {
                compile.writeln("    mov %d(%%rbp),%%rax",params)
                compile.writeln("    mov %%rax,%s",compile.args64[i])
                params += -8
            }
        }

        compile.writeln("    mov -8(%%rbp),%%rax")
        internal.get_object_value()
        if this.is_delref 
            compile.writeln("    sub $6,%%rax")
        else
            compile.writeln("    sub $5,%%rax")

        compile.writeln("    mov %%rax,%d(%%rbp)",currentFunc.size)
        compile.writeln("    mov $%d,%%rax",stack_offset)
        compile.writeln("    mov %%rax,%d(%%rbp)",currentFunc.stack)


        compile.writeln("    jmp L.while.end.%d",c)
        compile.writeln("L.while.%d:",c)

        compile.writeln("    mov %d(%%rbp),%%rax",currentFunc.size)
        compile.writeln("    imul $8,%%rax")
        compile.writeln("    add $%d,%%rax",stack_offset)
        compile.writeln("    mov %%rax,%d(%%rbp)",currentFunc.stack)
        compile.writeln("    lea (%%rbp),%%rax")

        compile.writeln("    add %d(%%rbp),%%rax",currentFunc.stack)
        compile.writeln("    mov (%%rax),%%rax")
        compile.writeln("    push %%rax")

        compile.writeln("    sub $1,%d(%%rbp)",currentFunc.size)
        
        compile.writeln("L.while.end.%d:",c)
        compile.writeln("    mov %d(%%rbp),%%rax",currentFunc.size)
        compile.writeln("    cmp $0,%%rax")
        compile.writeln("    jg  L.while.%d",c)

    }else{
        argsize = 6
        if fc.is_variadic argsize = 5

        if std.len(this.args) < argsize
            for (i = 0; i < (argsize - std.len(this.args)); i += 1){
                compile.writeln("    push $0")
            }
        
        for (i = std.len(this.args) - 1; i >= 0; i -= 1) {
            if gp >= compile.GP_MAX {
                stack += 1
            }
            gp += 1
            ret = this.args[i].compile(ctx)
            if ret != null && type(ret) == type(gen.StructMemberExpr) {
                sm = ret
                compile.LoadMember(sm.getMember())
            }else if ret != null && type(ret) == type(gen.ChainExpr) {
                ce = ret
                if type(ce.last) == type(gen.MemberCallExpr) {
                }else if type(this.args[i]) != type(gen.AddrExpr) {
                    compile.LoadMember(ce.ret)
                }
            }
            compile.Push()
        }
        
        if fc.is_variadic {
            
            if std.len(this.args) >= 6 {
                stack += 1
            }
            internal.newobject(ast.Int,std.len(this.args))

            compile.Push()
        }
    }

    if stack < 0 return 0
    else         return stack
}