Package::genStruct(s)
{
  
  bits = 0
  align = 1
  
  for(mem : s.member){
    
    if mem.isstruct {
        ps = (Parser*)s.parser
        acualPkg = ps.import[mem.structpkg]
        dst = Package::getStruct(acualPkg,mem.structname)
        if dst == null
            parse_err("struct.member: inner class not exist <%s.%s> line:%d column:%d file:%s\n"
            ,mem.structpkg,mem.structname,
            mem.line,mem.column,mem.file
            )
        
        mem.align = 8
        if !dst.iscomputed && !mem.pointer{
            genStruct(dst)
            assert(dst.iscomputed)
            mem.align = dst.align
        }
        mem.size  = mem.pointer ? 8 : dst.size
        
        mem.structref = dst
    }

    
    if (mem.bitfield && mem.bitwidth == 0) 
    {
      bits = ALIGN_UP(bits, mem.size * 8)
    } else if (mem.bitfield) 
    {
      sz = mem.size
      if (bits / (sz * 8) != (bits + mem.bitwidth - 1) / (sz * 8))
        bits = ALIGN_UP(bits, sz * 8)

      mem.offset = ALIGN_DOWN(bits / 8, sz)
      mem.bitoffset = bits % (sz * 8)
      bits += mem.bitwidth
    } else 
    {
        if !s.ispacked
          bits = ALIGN_UP(bits,mem.align * 8)
        mem.offset = bits / 8
        
        if mem.pointer
          bits += 8 * 8 * mem.arrsize
        else
          bits += mem.size * 8 * mem.arrsize
    }
    if !s.ispacked && align < mem.align
      align = mem.align
  }
  
  s.size = ALIGN_UP(bits, align * 8) / 8
  s.align = align
  
  s.iscomputed = true
}

Package::compile()
{
    asmfile  =   "sysinit.s"
    if package != "main"
        asmfile  = "co_" + package + "_" + asmfile

    out = std.fopen(asmfile)
    Compiler::out = out

    if out <= 0 {
        parse_err("genrate assembly file failed package:%s file:sysinit.s",package)
    }
    
    for(it : classes){
      if !checkClassFunc(it.first,"init"){
        funcname = full_package + "_" + it.first + "_init"
        
        Compiler::writeln(".global %s", funcname)
        Compiler::writeln("%s:", funcname)
        Compiler::writeln("    ret")
      }
    }
    out.close()
    Compiler::out = null

    for(p : parsers){
        p.compile()
    }
}