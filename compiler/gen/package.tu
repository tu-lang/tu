use parser.package
use ast
use compile

package.Package::genStruct(s)
{
  
  bits = 0
  align = 1
  
  for(mem : s.member){
    
    if mem.isstruct {
        ps = s.parser # Parser
        acualPkg = ps.import[mem.structpkg]
        dst = package.getStruct(acualPkg,mem.structname)
        if dst == null {
            panic("struct.member: inner class not exist <%s.%s> line:%d column:%d file:%s\n",
              mem.structpkg,mem.structname,mem.line,mem.column,mem.file
            )
        }
        
        mem.align = 8
        if !dst.iscomputed && !mem.pointer {
            genStruct(dst)
            assert(dst.iscomputed)
            mem.align = dst.align
        }
        // TODO: mem.size  = mem.pointer ? 8 : dst.size
        if mem.pointer != null mem.size = 8
        else                   mem.size = dst.size
        
        mem.structref = dst
    }

    
    if mem.bitfield && mem.bitwidth == 0 {
      bits = ast.ALIGN_UP(bits, mem.size * 8)
    }else if mem.bitfield{
      sz = mem.size
      if (bits / (sz * 8) ) !=  ((bits + mem.bitwidth - 1) / (sz * 8))
        bits = ast.ALIGN_UP(bits, sz * 8)

      mem.offset = ast.ALIGN_DOWN(bits / 8, sz)
      mem.bitoffset = bits % (sz * 8)
      bits += mem.bitwidth
    } else 
    {
        if !s.ispacked  bits = ast.ALIGN_UP(bits,mem.align * 8)

        mem.offset = bits / 8
        if mem.pointer
          bits += 8 * 8 * mem.arrsize
        else
          bits += mem.size * 8 * mem.arrsize
    }
    if !s.ispacked && align < mem.align
      align = mem.align
  }
  
  s.size = ast.ALIGN_UP(bits, align * 8) / 8
  s.align = align
  
  s.iscomputed = true
}

pacakge.Package::compile()
{
    asmfile  =   "sysinit.s"
    if this.package != "main"
        asmfile = fmt.sprintf("co_%s_%s",this.package,asmfile)

    out = new std.File(asmfile)
    if !out.IsOpen() {
        panic("genrate assembly file failed package:%s file:sysinit.s",package)
    }
    compile.out = out

    for(it : classes){
      if !checkClassFunc(it.first,"init"){
        funcname = fmt.printf("%s_%s_init",full_package,it.first)
        
        compile.writeln(".global %s", funcname)
        compile.writeln("%s:", funcname)
        compile.writeln("    ret")
      }
    }
    out.Close()
    compile.out = null

    for(p : parsers){
        p.compile()
    }
}