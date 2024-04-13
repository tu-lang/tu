use compiler.gen 
use compiler.ast
use std
use os
use compiler.parser
use compiler.parser.package

func InitStructVar(gvar , s , fields){
    utils.debug("compile.InitStructVar()")
	gvar.check(s != null,"struct is null in iniststructvar")
	size = 0
	for (m : s.member){
		if(size != m.offset){
			diff = m.offset - size
			writeln("   .zero %d",diff)
			size += diff
		}
		mt = "byte"
		if(m.isarr){
			gvar.check(ast.isbase(m.type),"unsupport struct type arr")
			elmentsize = m.size
			ltok = m.type
			if(m.pointer) {
				elmentsize = 8
				ltok = ast.U64
			}
			if fields[m.name] != null{
				fields[m.name].check(type(fields[m.name]) == type(gen.ArrayExpr),"must be array expr")
				arr = fields[m.name].lit
				if(m.arrsize != std.len(arr) ) {
					gvar.check(false,"global struct arr size is not same")
				}
				mt = ast.typesizestring(ltok)
				if(m.structname == "" || m.pointer ){
					for(i : arr){
						if type(i) == type(gen.IntExpr) {
                            writeln("   .%s %s",mt,i.lit)
                        }else{
                            if ltok == ast.F32 {
                                writeln("   .%s %s",mt,
                                    string.tostring(i.tof32())
                                )
                            }else if ltok == ast.F64 {
                                writeln("   .%s %s",mt,
                                    string.tostring(i.lit)
                                )
                            }else{
                                gvar.check(false,"something wroing in float cond")
                            }
                        }
					}
				}else{
					s = package.getStruct(m.structpkg,m.structname) 
					for(i : arr){
						me = i.lit
						if std.len(s.member) != std.len(me) {
							gvar.check(false,"s.member.size() != me.size()")
						}
						j = 0
						sz = 0
						for(_m : s.member){
							if(sz > _m.offset) gvar.check(false,"sz > _m.offset")
							if (sz < _m.offset){
								writeln("   .zero %d",_m.offset - sz)
								sz = _m.offset
							}
							_mtk = _m.type
							if(_m.pointer) _mtk = ast.U64
							_mt = ast.typesizestring(_mtk)
							writeln("   .%s %s",_mt,me[j].lit)
							sz += _m.size
							j += 1
						}
						if(sz > s.size)gvar.check(false,"sz < s.size")
						if (sz < s.size){
							writeln("   .zero %d",s.size - sz)
						}
					}
				}
			}else {
				writeln("   .zero %d",m.arrsize * elmentsize)
			}
			size += m.arrsize * elmentsize

		}else if(m.pointer){
			mt = "quad"
			if fields[m.name] != null {
				gvar.check(type(fields[m.name]) == type(gen.IntExpr),"must be int")
				ie = fields[m.name]
				writeln("   .quad %s",ie.lit)
			}else{
				writeln("   .quad 0")
			}
			size += 8
		}else if(m.structname != ""){
			sm = package.getStruct(m.structpkg,m.structname)
			gvar.check(sm != null,
				fmt.sprintf(
					"struct not exist in member %s.%s",
					m.structpkg,m.structname
				)
			)
			mfields = {}
			if fields[m.name] != null {
				mfields = fields[m.name].fields
			} 
			size += InitStructVar(gvar,sm,mfields)
		}else{
			gvar.check(ast.isbase(m.type),"must be base type i8 - u64")
			si = parser.typesize[int(m.type)]
			mt = ast.typesizestring(m.type)
			v = "0"
			if fields[m.name] != null {
				fields[m.name].check(
                    type(fields[m.name]) == type(gen.IntExpr) ||
                    type(fields[m.name]) == type(gen.FloatExpr),
                    "only support base type"
                )
				expr = fields[m.name]
                if type(expr) == type(gen.IntExpr)
					v = expr.lit
                else{
					fexpr = expr
                    if m.type == ast.F32 
                        v = string.tostring(fexpr.tof32())
                    else
                        v = string.tostring(fexpr.lit)
                    
                }
			}
			writeln("   .%s %s",mt,v)
			size += si
		}

	}
	return size
}