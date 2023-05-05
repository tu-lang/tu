use ast
use elf
use utils
use parser
use std
use fmt
use os

Asmer::init(filename)
{
    utils.debug("Asmer::init %s".(i8),*filename)
    this.text = 0
    this.bytes = 0
    this.elf   = new elf.ElfFile(this)
    this.parser = new parser.Parser(filename,this.elf)
    outname    = this.parser.outname
    fp<i32>    = utils.fopen(outname,"w+")
    if fp <= 0 {
        utils.error("open failed " + outname)
    }
    this.out   = fp
}
//start
Asmer::execute() {
    utils.debug("Asmer::execute".(i8))
    this.parser.parse()
    this.data = this.parser.data_size
    this.buildElf()
    this.writeElf()
}
//pre build elf
Asmer::buildElf() {
    utils.debug("Asmer::buildElf".(i8))
    elfh<elf.ElfFile> = this.elf
    elfh.buildEhdr()
    elfh.buildText()
    elfh.buildData()
    //entry address
    elfh.ehdr.e_shoff = elfh.offset
    elfh.buildSectab()
    elfh.buildShstrtab()
    elfh.buildSymtab()
    elfh.buildStrtab()
    elfh.buildRelTab()
}
//write elf
Asmer::writeElf() {
    utils.debug("Asmer::writeElf".(i8))
    ehdr<elf.Elf64_Ehdr> = &this.elf.ehdr
    offset<i32> = 0
    this.writeBytes(&this.elf.ehdr,this.elf.ehdr.e_ehsize)
    offset += this.elf.ehdr.e_ehsize
    this.check(this.bytes == offset,"1 bytes != offset :" + int(this.bytes) + " : " + int(offset))

    this.InstWrite()
    offset += this.text
    this.check(this.bytes == offset)

    data_size<i32>  = this.parser.symtable.data_symbol.len() 
    ds<i32> = 0
    i<i32> = 0
    data_symbol<std.Array> = this.parser.symtable.data_symbol
    for(i<i32> = 0 ; i < data_symbol.len() ; i += 1){
        sym<ast.Sym> =  data_symbol.addr[i]
        if sym.isstr {
            this.writeBytes(sym.str.str(),sym.str.len() + Pad1)
        }else{//[block,block...]
            for(j<i32> = 0 ; j < sym.datas.len() ; j += 1){
                b<ast.ByteBlock> = sym.datas.addr[j]
                tysize<i32> = ast.typesize(b.type)
                if b.type == ast.KW_ZERO {
                    this.writePads(b.data)
                }else{
                    this.writeBytes(b.data,tysize)
                }
            }
        }
    }
    offset += this.data
    this.check(this.bytes == offset,"3 bytes != offset :" + int(this.bytes) + " : " + int(offset))
    shdrTab = this.elf.shdrTab
    for(i<i32> = 0 ; i < this.elf.shdrNames.len() ; i += 1){
        name = this.elf.shdrNames.addr[i]
        sh<elf.Elf64_Shdr> = shdrTab.find(name)
        this.writeBytes(sh,this.elf.ehdr.e_shentsize)
    }
    // FIXME: offset += this.elf.ehdr.e_shentsize * 8
    offset += ehdr.e_shentsize * 8
    this.check(this.bytes == offset,"2 bytes != offset :" + int(this.bytes) + " : " + int(offset))
    this.writeBytes(this.elf.shstrtab,this.elf.shstrtab_size)
    offset += this.elf.shstrtab_size
    this.check(this.bytes == offset)

    symTab = this.elf.symTab
    for( i<i32> = 0 ; i < this.elf.symNames.len() ; i += 1){
        symname = this.elf.symNames.addr[i]
        sym<elf.Elf64_Sym> = symTab[symname]
        this.writeBytes(sym,sizeof(elf.Elf64_Sym))
    }
    offset += this.elf.symNames.len() * sizeof(elf.Elf64_Sym)
    this.check(this.bytes == offset)
    this.writeBytes(this.elf.strtab,this.elf.strtab_size)
    offset += this.elf.strtab_size
    this.check(this.bytes == offset)

    for(i<i32> = 0 ; i < this.elf.relTextTab.len() ; i += 1){
        rel = this.elf.relTextTab.addr[i]
        this.writeBytes(rel,sizeof(elf.Elf64_Rela))
    }
    offset += this.elf.relTextTab.len() * sizeof(elf.Elf64_Rela)
    this.check(this.bytes == offset)

    for(i<i32> = 0 ; i < this.elf.relDataTab.len() ;i += 1){
        rel = this.elf.relDataTab.addr[i]
        this.writeBytes(rel,sizeof(elf.Elf64_Rela))
    }
    offset += this.elf.relDataTab.len() * sizeof(elf.Elf64_Rela)
    this.check(this.bytes == offset)
}
// void b, int len
Asmer::writeBytes(b<u64*>, len<i32>)
{
    this.bytes += len
    utils.fwrite(this.out,b,len)
}
// void b, int len
Asmer::writePads(len<i32>)
{
    this.bytes += len
    b<i32:20> = null // int[20]
    size<i32> = len
    while(size > 0){
        ws<i32> = size
        if(size >= 8)
            ws = 8
        size -= 8
        utils.fwrite(this.out,&b,ws)
    }
}


Asmer::check(check<i32>,err<u64>)
{
    if(check) return true
    if err != null {
        fmt.printf(
            "asmer: found error\n"
            "msg:%s\n"
            "file:%s\n",
            err,
            this.parser.filepath
        )
    }
    os.die(" ")
}