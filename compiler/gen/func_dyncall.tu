
use compiler.ast 
use compiler.compile
use compiler.internal
use compiler.parser
use compiler.parser.package
use std
use compiler.utils


FunCallExpr::dynstackcall(ctx, ty, free){

	args = this.args
	cfunc = compile.currentFunc
	vlid = ast.incr_labelid()	
	argsvardic_label = cfunc.fullname() + "_cfv_" + vlid
	argseq_label   = cfunc.fullname() + "_cfe_" + vlid
	argsdone_label   = cfunc.fullname() + "_done_" + vlid
	dynfuture_label   = cfunc.fullname() + "_dynf_" + vlid

    //push argn,argn-1,arg....,arg1 ,argcount
    stack_args = this.DynPushStackArgs(ctx)
    vfinfo = stack_args * 8
    vfinfo += 8

	compile.writeln("    mov %d(%%rsp) , %%rax", vfinfo)
    //rfc100-4:
    if ty != ast.FutureCall {
        compile.writeln(
            "   cmp $0 , 52(%%rax)\n" +
            "   jle %s\n" +
            "   push $%d\n" +
            "   push %%rax\n" +
            "   call runtime_dynfuturenew2\n" +
            "   add $%d , %%rsp\n" +
            "   lea runtime_default_virfuture , %%rdi\n" +
            "   mov %%rdi , %d(%%rsp)\n" +
            "   jmp %s", //over
            dynfuture_label, stack_args, stack_args * 8,
            8, argsdone_label
        )
        compile.writeln("%s:",dynfuture_label)
    }

    compile.writeln("    cmp $1 , 16(%%rax)")
    compile.writeln("    je %s",argsvardic_label)

	compile.writeln("    cmpq $%d , 24(%%rax)",std.len(args) * 8)
    compile.writeln("    je %s",argseq_label)
    //1. variadic
	compile.writeln("%s:",argsvardic_label)
	compile.writeln("    push $%d",stack_args)
	compile.writeln("	 sub 24(%%rax) , %%rsp")
    compile.writeln("    sub $8 , %%rsp") //padding for retstack
	compile.Push()
    compile.writeln("    push $%d", ty)
	internal.dynarg_pass() 

    compile.writeln("    call *%%rax")
    compile.writeln("    add $%d , %%rsp",(stack_args + 1 + 1) * 8 )
    compile.writeln("    jmp %s",argsdone_label)
    //2. eq
    compile.writeln("%s:",argseq_label)
    compile.writeln("    mov 8(%%rax) , %%r10")
    compile.writeln("    call *%%r10")
    // compile.Pop("%rdi") 
    //3. done
    compile.writeln("%s:",argsdone_label)
    if free {
        this.dynfreeret()
    }

    return null    
}

FunCallExpr::DynPushStackArgs(prevCtxChain)
{
	stack = 0
	hashvariadic = this.hasVariadic()
	for  i = std.len(this.args) - 1; i >= 0; i -= 1 {
		arg = this.args[i]
		ret = arg.compile(prevCtxChain,true)

        if ret != null {
			ty<i32> = ret.getType(prevCtxChain)
            if ast.isfloattk(ty)
                compile.Pushf(ty)
            else
                compile.Push()
        }else   compile.Push()
	
		stack += 1
	}
	return stack
}

FunCallExpr::dynstackcall2(ctx,free){
	args = this.args
	cfunc = compile.currentFunc
	vlid = ast.incr_labelid()
	argsvardic_label = cfunc.fullname() + "_cfv2_" + vlid

	compile.writeln("    cmpq $%d , 24(%%rax)",std.len(args) * 8)
    compile.writeln("    je %s",argsvardic_label)

    compile.writeln("    call runtime_dynarg_varadicerr1")
    compile.writeln("%s:",argsvardic_label)
    //push argn,argn-1,arg....,arg1 ,argcount
    stack_args = this.DynPushStackArgs(ctx)
	compile.writeln("    mov %d(%%rsp) , %%rax", (stack_args + 1) * 8)
    compile.writeln("    mov 8(%%rax) , %%r10")
    compile.writeln("    call *%%r10")
    // compile.Pop("%rdi")
    // compile.Pop("%rdi")
    if free {
        this.dynfreeret()
    }

    return null
}