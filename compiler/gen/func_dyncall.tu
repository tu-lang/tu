
use compiler.ast 
use compiler.compile
use compiler.internal
use compiler.parser
use compiler.parser.package
use std
use compiler.utils

FunCallExpr::dyncompile(ctx, ty, obj){
	match ty {
    	ast.ChainCall: {
            internal.get_func_value()
			compile.writeln(" mov %%rax , (%%rsp)")
    	}
    	ast.MemberCall: {
			internal.object_func_addr2(this,this.funcname)
			compile.Push()
    	}
    	ast.ObjCall: {
			compile.GenAddr(obj)
        	compile.Load()
        	compile.Push()

			internal.object_func_addr2(this,this.funcname)
			compile.Push()
		}
    	ast.ClosureCall: {
			compile.GenAddr(obj)
        	compile.Load()
			internal.get_func_value()
			compile.Push()
		}
    	_: this.check(false,"unknown dyn compile")
    }

	this.dynstackcall(ctx)
	compile.writeln("	add $8 , %%rsp")
	return null
}

FunCallExpr::dynstackcall(ctx){
	args = this.args
	cfunc = compile.currentFunc

    stack_args = this.DynPushStackArgs(ctx)

    //push funcaddr,argn,argn-1,arg....,arg1
    compile.writeln("    mov %d(%%rsp),%r10",stack_args * 8)
    compile.writeln("    mov $0, %%rax")
    compile.writeln("    call *%%r10")

    compile.writeln("    add $%d, %%rsp", stack_args * 8)
    return null    
}

FunCallExpr::DynPushStackArgs(prevCtxChain)
{
	stack = 0
	hashvariadic = this.hasVariadic()
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
