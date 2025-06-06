use compiler.parser.package
use compiler.ast
use compiler.compile
use compiler.utils
use string

fn genStruct(s)
{
	utils.debug("gen.package.Package::genStruct()")  
	bits = 0
	align = 1

	// compile.currentParser = s.parser
	p  = s.parser
	
	for(m : s.member){
		compile.currentParser = p

		if !s.asyncobj && m.isstruct {
			ps = s.parser // Parser
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
				genStruct(dst)
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
	if s.asyncfn != null {
		compile.genFuture(s.asyncfn)
	}
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

	//gc moudle list ptr
    prev = null
    for p : this.parsers {
		if std.len(p.gvars) == 0	
			continue

		if prev == null {
			this.fparser = p
		}else{
			prev.next = p
		}
		prev = p
    }

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

	if package.packages[pkgname] == null {
		pkgname = ast.GP().getImport(pkgname)
		if package.packages[pkgname] == null 
			return null
    }
	pkg = package.packages[pkgname]
	return pkg.getFunc(name,false)
}

package.Package::hasGcMoudle() {
	for p : this.parsers {
		if std.len(p.gvars) > 0 {
			return true
		}
	}
	return false
}