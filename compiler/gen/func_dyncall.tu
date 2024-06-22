
use compiler.ast 
use compiler.compile
use compiler.internal
use compiler.parser
use compiler.parser.package
use std
use compiler.utils

FunCallExpr::dyncompile(ctx, ty, funcname){
	match ty {
    	ast.ChainCall: {
            internal.get_func_value_nq()
			fc = new ast.Function()
        	fc.isExtern    = false
        	fc.isObj       = true
        	fc.is_variadic = false
        	this.call(ctx,fc)
        	compile.writeln("   add $8,%%rsp")
        	return null
    	}
    	ast.MemberCall: {
			internal.object_func_addr2(this,funcname)
			compile.Push()
			fc = new ast.Function()
			fc.isExtern    = false
			fc.isObj       = true
			fc.is_variadic = false
			this.call(ctx,fc)
			compile.writeln("   add $8,%%rsp")
			return null
    	}
    	ast.ObjCall: {
			internal.object_func_addr2(this,funcname)
			compile.Push()
			fc = new ast.Function()
			fc.isExtern    = false
			fc.isObj       = true
			fc.is_variadic = false
			this.call(ctx,fc)
			compile.writeln("   add $8,%%rsp")
			return null
		}
    	ast.ClosureCall: {
			var = ctx.getOrNewVar(funcname)
			compile.GenAddr(var)
			compile.Load()
			if !var.structtype
				internal.get_func_value()
			compile.Push()
			fc = new ast.Function()
			fc.isExtern    = false
			fc.isObj       = true
			fc.is_variadic = false
			this.call(ctx,fc)

			compile.writeln("   add $8,%%rsp")
			return null
		}
    	_: this.check(false,"unknown dyn compile")
    }
}