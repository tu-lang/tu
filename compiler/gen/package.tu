use compiler.parser.package
use compiler.ast
use compiler.compile
use compiler.utils
use string

package.Package::genStruct(s)
{
	utils.debug("gen.package.Package::genStruct()")  
	bits = 0
	align = 1

	// compile.currentParser = s.parser
	p  = s.parser
	
	for(m : s.member){
		compile.currentParser = p
		if m.isstruct {
			ps = s.parser # Parser
			compile.currentParser  = ps
			acualPkg = ps.getImport(m.structpkg)
			dst = package.getStruct(acualPkg,m.structname)
			if dst == null {
				p.panic(
					fmt.sprintf(
						"struct.member: inner class not exist <%s.%s>\n",
						m.structpkg,
						m.structname,
					)
				)
			}
        
			m.align = 8
			if !dst.iscomputed && !m.pointer {
				this.genStruct(dst)
				if !dst.iscomputed os.panic("dst is not computed")
				m.align = dst.align
			}
			// TODO: mem.size  = mem.pointer ? 8 : dst.size
			if m.pointer != null m.size = 8
			else                   m.size = dst.size
			
			m.structref = dst
			compile.currentParser = p
		}
		if m.pointer {
			m.align = 8
		}
    
		if m.bitfield && m.bitwidth == 0 {
			bits = utils.ALIGN_UP(bits, m.size * 8)
		}else if m.bitfield{
			sz = m.size
			if (bits / (sz * 8) ) !=  ((bits + m.bitwidth - 1) / (sz * 8))
				bits = utils.ALIGN_UP(bits, sz * 8)

			m.offset = utils.ALIGN_DOWN(bits / 8, sz)
			m.bitoffset = bits % (sz * 8)
			bits += m.bitwidth
		} else 
		{
			if !s.ispacked  bits = utils.ALIGN_UP(bits,m.align * 8)

			m.offset = bits / 8
			arrcount = m.getarrcount()
			if arrcount == 0 s.parser.check(false,"arrcount == 0")
			if m.pointer
				bits += 8 * 8 * arrcount
			else
				bits += m.size * 8 * arrcount
		}
		if !s.ispacked && align < m.align
		align = m.align
	}
	if s.ispacked {
		s.size = utils.ALIGN_UP(bits, align * 8) / 8
		s.align = align
	} else {
		s.size = utils.ALIGN_UP(bits, 8 * 8) / 8
		s.align = align
	} 
	
	s.iscomputed = true
	compile.currentParser = null
}
package.Package::classinit(){
    utils.debugf("gen.Package::classinit()")
	for(pkg : package.packages){
		for(cls : pkg.classes){
			if !cls.found continue
			cls.initClassInitFunc()
		}
	}
}
package.Package::compile(){
    utils.debugf("gen.Package::compile()")

	for(p : this.parsers){
		p.compile()
	}
}

package.Package::defaultvarsinit(){
    utils.debugf("gen.Package::defaultvarsinit()")
	if !compile.debug && !compile.sdebug return true
	debug = package.packages["runtime_debug"]
	for p : debug.parsers {
		for var : p.gvars {
			if var.varname == "enabled" {
				var.ivalue = "1"
				return true
			}
		}
	}
}

fn getGLobalFunc(pkgname ,name){
	if pkgname == "" {
		pkgname  = compile.currentFunc.parser.getpkgname()
	}
	pkg  = package.packages[pkgname]
    if !pkg {
		return null
    }
	return pkg.getFunc(name,false)
}