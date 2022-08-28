use parser.package
use ast
use compile
use utils

package.Package::genStruct(s)
{
  
  bits = 0
  align = 1
  
  for(m : s.member){
    
    if m.isstruct {
        ps = s.parser # Parser
        acualPkg = ps.import[m.structpkg]
        dst = package.getStruct(acualPkg,m.structname)
        if dst == null {
            this.panic("struct.member: inner class not exist <%s.%s> line:%d column:%d file:%s\n",
              m.structpkg,m.structname,m.line,m.column,m.file
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
        if m.pointer
          bits += 8 * 8 * m.arrsize
        else
          bits += m.size * 8 * m.arrsize
    }
    if !s.ispacked && align < m.align
      align = m.align
  }
  
  s.size = utils.ALIGN_UP(bits, align * 8) / 8
  s.align = align
  
  s.iscomputed = true
}
package.Package::classinit(){
  for(pkg : package.packages){
    for(cls : pkg.classes){
      cls.initClassInitFunc()
      cls.checkRmSupers()
    }
  }
}
package.Package::compile(){
    for(p : this.parsers){
        p.compile()
    }
}