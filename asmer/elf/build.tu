use asmer.ast
use asmer.utils
use std
use string

ElfFile::buildEhdr() {
    utils.debug("ElfFile::buildEhdr".(i8))
    p_id<i32*> = &this.ehdr.e_ident
    p_id[0]    = 0x464c457f
    p_id[1]    = 0x010102
    p_id[2]    = 0
    p_id[3]    = 0
    this.ehdr.e_type      = ET_REL
    this.ehdr.e_machine   = EM_X86_64
    this.ehdr.e_version   = EV_CURRENT
    this.ehdr.e_flags     = 0

    this.ehdr.e_entry     = 0
    this.ehdr.e_phoff     = 0
    this.ehdr.e_phentsize = 0
    this.ehdr.e_phnum     = 0
    this.ehdr.e_ehsize    = sizeof(Elf64_Ehdr)
    this.ehdr.e_shentsize = sizeof(Elf64_Shdr)
    this.ehdr.e_shnum     = 8
    this.ehdr.e_shstrndx  = 3

    this.ehdr.e_shoff = sizeof(Elf64_Ehdr)

    this.offset = sizeof(Elf64_Ehdr)
    utils.debug("header:[0,%d]".(i8),this.offset)
}
ElfFile::buildSectab(){
    utils.debug(
        "section tab:[%d,%d]".(i8),
        this.offset,
        this.offset + sizeof(Elf64_Shdr) * 8
    )
    this.offset     += sizeof(Elf64_Shdr) * 8
}
ElfFile::buildData(){
    this.addTDShdr(string.S(*".data"),this.asmer.data)
    utils.debug(*"ElfFile::buildData:[%d,%d]",
        this.offset,this.offset + this.asmer.data
    )
    this.offset     += this.asmer.data
    this.addSectionSym()
    iter<map.MapIter> = this.asmer.parser.symtable.symbols.iter()
    while iter.next() != map.End {
        sym<ast.Sym> = iter.v()
        this.addSym(sym)
    }
}
ElfFile::buildText(){
    this.addTDShdr(string.S(*".text"),this.asmer.parser.text_size)
    utils.debug(
        *"ElfFile::buildText() [%d,%d]",
        this.offset,
        this.offset + this.asmer.parser.text_size
    )
    this.offset += this.asmer.parser.text_size
    this.asmer.text = this.asmer.parser.text_size
}
ElfFile::buildShstrtab() {
    utils.debug(*"ElfFile::buildShstrtab()")
    reltext<string.String>  = string.S(*".rela.text")
    reldata<string.String>  = string.S(*".rela.data")
    shstrtab<string.String> = string.S(*".shstrtab")
    symtab<string.String>   = string.S(*".symtab")
    strtab<string.String>   = string.S(*".strtab")
    pading<string.String>   = string.S(*"      ")

    shstrtab_size<i32> = reltext.len() + Pad1 +
        reldata.len() + Pad1 +
        shstrtab.len()+ Pad1 +
        symtab.len()  + Pad1 +
        strtab.len()  + Pad1 +
        pading.len()

    str<i8*> = new shstrtab_size
    this.shstrtab_size = shstrtab_size
    this.shstrtab  = str

    index<i32>       = 0
    this.strIndex.insert(string.S(*".rela.text"), index)
    std.strcopy(str + index, *".rela.text")

    this.strIndex.insert(string.S(*".text")     ,index + 5)
    index += reltext.len() + Pad1

    this.strIndex.insert(string.S(*"")          ,index - 1)
    this.strIndex.insert(string.S(*".rela.data"),index)
    std.strcopy(str + index, *".rela.data")

    this.strIndex.insert(string.S(*".data")      ,index + 5)
    index += reldata.len() + Pad1

    this.strIndex.insert(string.S(*".shstrtab")  ,index)
    std.strcopy(str + index, *".shstrtab")
    index += shstrtab.len() + Pad1

    this.strIndex.insert(string.S(*".symtab")    ,index)
    std.strcopy(str + index, *".symtab")

    index += symtab.len() + Pad1
    this.strIndex.insert(string.S(*".strtab")     , index)
    std.strcopy(str + index, *".strtab")
    index += strtab.len() + Pad1

    this.addShdr(
        string.S(*".shstrtab"), SHT_STRTAB, 0.(i8), 0.(i8), 
        this.offset, 
        this.shstrtab_size, SHN_UNDEF, 0.(i8), 1.(i8), 0.(i8)
    )//.shstrtab
    utils.debug(
        *"shstrtable:[%d,%d]",
        this.offset,this.offset + this.shstrtab_size
    )
    this.offset += this.shstrtab_size
}
ElfFile::buildSymtab() {
    utils.debug("ElfFile::buildSymtab()".(i8))
    this.sortGlobal()
    this.strtab_size = this.symNames.len() * sizeof(Elf64_Sym)
    utils.debug(
        *"symtab: offset[%d,%d] size:%d", 
        this.offset, this.offset + this.strtab_size, this.strtab_size
    )
    this.addShdr(
        string.S(*".symtab"), 
        SHT_SYMTAB, 0.(i8), 0.(i8), 
        this.offset,this.strtab_size, 0.(i8), 0.(i8), 8.(i8), sizeof(Elf64_Sym)
    )
    this.offset += this.strtab_size
    //TODO: static chain
    // this.shdrTab.find(string.S(*".symtab")).(Elf64_Shdr).sh_link = this.getSegIndex(
        // string.S(*".symtab")
    // )
    s<Elf64_Shdr> = this.shdrTab.find(string.S(*".symtab"))
    s.sh_link = this.getSegIndex(string.S(*".symtab")) + Pad1
    s.sh_info = this.sh_info
}
ElfFile::buildStrtab() {
    utils.debug("ElfFile::buildStrtab()".(i8))
    this.strtab_size = 0
    symNames<std.Array>  = this.symNames
    for (i<i32> = 0; i < this.symNames.len(); i += 1) {
        this.strtab_size += symNames.addr[i].(string.String).len() + Pad1
    }
    this.addShdr(
        string.S(*".strtab"), 
        SHT_STRTAB, 0.(i8), 0.(i8), 
        this.offset, 
        this.strtab_size, 
        SHN_UNDEF, 0.(i8), 1.(i8), 0.(i8)
    )//.strtab
    allstrsize<i32> = this.strtab_size
    str<i8*> = new allstrsize
    this.strtab = str
    index<i32> = 0
    for(i<i32> = 0 ; i < this.symNames.len() ; i += 1){
        strname<string.String> = this.symNames.addr[i]
        es<Elf64_Sym> = this.symTab.find(strname)
        es.st_name = index
        std.strcopy(str + index, strname.str())
        index += strname.len() + Pad1
    }
    utils.debug(
        *"strtab:[%d,%d]",
        this.offset,this.offset + this.strtab_size
    )
    this.offset += this.strtab_size
}
ElfFile::buildRelTab(){
    utils.debug("ElfFile::buildRelTab()".(i8))
    relTab<std.Array> = this.relTab 
    for(i<i32> = 0 ;i < this.relTab.len() ; i += 1)
    {
        rel<RelInfo> = this.relTab.addr[i]
        rela<Elf64_Rela> = new Elf64_Rela
        rela.r_offset  = relTab.addr[i].(RelInfo).offset
        rela.r_info    = ELF64_R_INFO(
            this.getSymIndex(
                relTab.addr[i].(RelInfo).name
            ),
            relTab.addr[i].(RelInfo).type
        )
        if rel.tarSeg.cmpstr(".data".(i8)) != string.Equal
            rela.r_addend  = -4

        if relTab.addr[i].(RelInfo).type == R_X86_64_PC32 {
            sym<ast.Sym> = this.asmer.parser.symtable.getSym(
                relTab.addr[i].(RelInfo).name
            )
            if !sym.externed {
                rela.r_info    = ELF64_R_INFO(
                    this.getSymIndex(
                        relTab.addr[i].(RelInfo).name
                    ),
                    relTab.addr[i].(RelInfo).type
                )
            }

        }
        tarSeg<string.String> = relTab.addr[i].(RelInfo).tarSeg
        if tarSeg.cmpstr(".text".(i8)) == string.Equal
            this.relTextTab.push(rela)
        else if tarSeg.cmpstr(".data".(i8)) == string.Equal
            this.relDataTab.push(rela)
    }
    text_size<i32> = this.relTextTab.len() * sizeof(Elf64_Rela)
    this.addShdr(
        string.S(*".rela.text"),
        SHT_RELA,SHF_INFO_LINK,0.(i8),
        this.offset,text_size,
        this.getSegIndex(string.S(*".symtab")),
        this.getSegIndex(string.S(*".text")),
        8.(i8), sizeof(Elf64_Rela)
    )//.rela.text
    utils.debug(*"text realation table:[%d,%d]",this.offset,this.offset + text_size)
    this.offset += text_size

    data_size<i32> = this.relDataTab.len() * sizeof(Elf64_Rela)
    this.addShdr(
        string.S(*".rela.data"),SHT_RELA,SHF_INFO_LINK,0.(i8),
        this.offset,data_size,
        this.getSegIndex(string.S(*".symtab")),
        this.getSegIndex(string.S(*".data")),
        8.(i8), sizeof(Elf64_Rela)
    )//.rel.data
    utils.debug(*"data realation table:[%d,%d]",this.offset,this.offset + data_size)
    this.offset += data_size
    for(i<i32> = 0 ; i < this.shdrNames.len() ; i += 1){
        index<i32> = this.strIndex.find(
            this.shdrNames.addr[i]
        )
        st<Elf64_Shdr> = this.shdrTab.find(
            this.shdrNames.addr[i]
        )
        st.sh_name = index
    }
}

