
use compiler.ast 
use compiler.compile
use compiler.internal
use compiler.parser
use compiler.parser.package
use std
use compiler.utils


FunCallExpr::call(ctx,fc,free)
{
	this.is_dyn = false
	this.fcs = fc
	if fc.block == null {
		compile.writeln("#    register %s",compile.currentFunc.fullname())
		return this.registercall(ctx,fc)
	}
	return this.stackcall(ctx,fc,free)
}

FunCallExpr::stackcall(ctx,fc,free)
{
	args = this.args
	callname = this.funcname
	cfunc = compile.currentFunc

	paramsize = std.len(fc.params_order_var)
	if fc.isasync()
		paramsize = 2

	if paramsize != std.len(this.args) 
		utils.debug("ArgumentError: expects %d arguments but got %d\n",std.len(fc.params_order_var),std.len(this.args))

	stack_args = this.PushStackArgs(ctx,fc)
	if fc.fntype != ast.ExternFunc {
		callname = fc.fullname()
	}
	compile.writeln("    call %s",callname)

    if stack_args > paramsize {
		delta = stack_args - paramsize
        compile.writeln("    add $%d, %%rsp", delta * 8)
    }
	if fc.mcount > 1 {
		// compile.Pop("%rdi")
		if free {
			compile.writeln("    add $%d, %%rsp", (fc.mcount - 1) * 8)
		}
	}
    return null
}

FunCallExpr::closcall(ctx , obj, free)
{
	fc = getGLobalFunc(obj.structpkg,obj.structname)
    this.check(fc != null," closcall func not define")

	this.is_dyn = false
	this.fcs    = fc

	args = this.args

    if std.len(fc.params_order_var) != std.len(this.args)
        utils.debugf("ArgumentError: expects %d arguments but got %d\n",std.len(fc.params_order_var),std.len(this.args))

	stack_args = this.PushStackArgs(ctx,fc)

    compile.GenAddr(obj)
    compile.Load()
    compile.writeln("    call *%%rax")

    if stack_args > std.len(fc.params_order_var) {
		delta = stack_args - std.len(fc.params_order_var)
        compile.writeln("    add $%d, %%rsp", delta * 8)
    }
	if fc.mcount > 1 {
		// compile.Pop("%rdi")
		if free {
			compile.writeln("    add $%d, %%rsp", (fc.mcount - 1) * 8)
		}
	}
    return null
}

FunCallExpr::PushStackArgs(ctx,fc)
{
	
	paramsize = std.len(fc.params_order_var)
	if fc.isasync()
		paramsize = 2

	stack = 0
	hashvariadic = this.hasVariadic()

    if fc.mcount > 1 {
		retstack = fc.mcount - 1
        compile.writeln("    sub $%d , %%rsp",retstack * 8)

        if hashvariadic && fc.is_variadic && (std.len(this.args) == paramsize) {
            stack += 1
            compile.writeln("    push %%rsp")
        }else if !fc.is_variadic {
            stack += 1
            compile.writeln("    push %%rsp")
        }
    }

	if hashvariadic && fc.is_variadic && (std.len(this.args) != paramsize) {
        this.check(false,"vardic args pass need eq")
    }
	
	if paramsize > std.len(this.args) {
		miss = paramsize - std.len(this.args)
		for i  = 0 ; i < miss ; i += 1 {
			stack += 1

			if i == 0 && fc.is_variadic {
                stack += 1
                if fc.mcount > 1 {
                    compile.writeln(
                        "    push $0\n" +
                        "    mov %%rsp , %%rdi\n" +
                        "    lea 8(%%rsp) , %%rcx\n" +
                        "    push %%rcx\n" +
                        "    push %%rdi\n" 
                    )
                    stack += 1
                }else{
                    compile.writeln("    push $0")
                    compile.writeln("    push %%rsp")
                }
                continue
            }
			if fc.params_order_var[std.len(fc.params_order_var) - 1 - i].structtype {
				compile.writeln("    push $0")
			}else{
				compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
				compile.Push()
			}
		}
	}

	staticcount = paramsize - 1
	for  i = std.len(this.args) - 1; i >= 0; i -= 1 {
		arg = this.args[i]

		if !fc.is_variadic && i > staticcount {
			utils.warn(
				" pass params too much in variadic pass, file:%s line:%d",
				compile.currentParser.filepath,
				this.line
			)
            continue
        }

		ret = arg.compile(ctx,true)
        if ret != null {
			ty<i32> = ret.getType(ctx)
            if ast.isfloattk(ty)
                compile.Pushf(ty)
            else
                compile.Push()
        }else   compile.Push()
	

		stack += 1
		//func(a,b,c,args...)
		//call(1,2,3,4)
		if !hashvariadic && fc.is_variadic && std.len(this.args) >= paramsize && i == staticcount {

			varidcnum = std.len(this.args) - staticcount
            if fc.mcount > 1 {
                compile.writeln(
                    "   push $%d\n" +
                    "   mov %%rsp , %%rdi\n" +
                    "   lea %d(%%rsp), %%rcx\n" +
                    "   push %%rcx\n" +
                    "   push %%rdi\n", 
                    varidcnum,
                    (varidcnum + 1) *8 
                )
                stack += 1
            }else{
                compile.writeln("    push $%d",varidcnum)
                compile.writeln("    push %%rsp")
            }

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
	if std.len(fc.params_order_var) != std.len(this.args)
		utils.debug("ArgumentError: expects %d arguments but got %d\n",std.len(fc.params_order_var),std.len(this.args))

	stack_args = this.PushRegisterArgs(ctx,fc)

	if !cfunc || !cfunc.is_variadic || !have_variadic
		for (i = 0; i < compile.GP_MAX; i+=1) {
			compile.Pop(compile.args64[gp])
			gp += 1
		}

	if fc.fntype == ast.ExternFunc {
		compile.writeln("    lea %s(%%rip), %%rax", funcname)
	}else{
		realfuncname = fc.fullname()
		compile.writeln("    lea %s(%%rip), %%rax", realfuncname)
	}

	compile.writeln("    mov %%rax, %%r10")
	compile.writeln("    mov $%d, %%rax", fp)
	compile.writeln("    call *%%r10")

	if compile.currentFunc && compile.currentFunc.is_variadic && have_variadic {
		c = ast.incr_labelid()
		compile.Push()
		compile.writeln("    push -8(%%rbp)")
		internal.call("runtime_get_object_value")
		compile.writeln("    mov %%rax,%d(%%rbp)",compile.currentFunc.stack)
		compile.Pop("%rax") 

		if(this.is_delref){
			compile.writeln("    add $-6,%d(%%rbp)",compile.currentFunc.stack)
		}else{
			compile.writeln("    add $-5,%d(%%rbp)",compile.currentFunc.stack)
		}
		compile.writeln("    cmp $0,%d(%%rbp)",compile.currentFunc.stack)
		compile.writeln("    jle %s.L.if.end.%d",compile.currentParser.label(), c)
		// compile.writeln("    cmp %d(%%rbp),%%rdi",compile.currentFunc.stack)
		// compile.writeln("    add $%d, %%rsp", stack_args * 8)
		compile.writeln("    mov %d(%%rbp),%%rdi",compile.currentFunc.stack)
		compile.writeln("    imul $8,%%rdi")
		compile.writeln("    add %%rdi, %%rsp")
		compile.writeln("%s.L.if.end.%d:",compile.currentParser.label(),c)
	}else{
		compile.writeln("    add $%d, %%rsp", stack_args * 8)
	}
	return null
}

FunCallExpr::hasVariadic(){
	count = std.len(this.args)
	for i = 0 ; i < count ; i +=1 {
		arg = this.args[i]
		if (type(arg) == type(gen.VarExpr) && compile.currentFunc){
			var = arg
			if( compile.currentFunc.params_var[var.varname] != null ){
				var2 = compile.currentFunc.params_var[var.varname]
				if(var2 && var2.is_variadic){
					if (i + 1) != count {
                        this.check(false,"pass vardic ,must be last postion")
                    }
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


        compile.writeln("    jmp %s.L.while.end.%d",compile.currentParser.label(),c)
        compile.writeln("%s.L.while.%d:",compile.currentParser.label(),c)

        compile.writeln("    mov %d(%%rbp),%%rax",currentFunc.size)
        compile.writeln("    imul $8,%%rax")
        compile.writeln("    add $%d,%%rax",stack_offset)
        compile.writeln("    mov %%rax,%d(%%rbp)",currentFunc.stack)
        compile.writeln("    lea (%%rbp),%%rax")

        compile.writeln("    add %d(%%rbp),%%rax",currentFunc.stack)
        compile.writeln("    mov (%%rax),%%rax")
        compile.writeln("    push %%rax")

        compile.writeln("    sub $1,%d(%%rbp)",currentFunc.size)
        
        compile.writeln("%s.L.while.end.%d:",compile.currentParser.label(),c)
        compile.writeln("    mov %d(%%rbp),%%rax",currentFunc.size)
        compile.writeln("    cmp $0,%%rax")
        compile.writeln("    jg  %s.L.while.%d",compile.currentParser.label(),c)

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
			this.args[i].compile(ctx,true)
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