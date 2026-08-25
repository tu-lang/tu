use asmer.instruct
use std
use string
use fmt
use os

mem Function {
    std.Array*        instructs // Instruct
    string.String*    labelname
}
Function::init(name){
    this.labelname = name
    this.instructs = std.NewArray()
}

mem ByteBlock {
    i32 type
    u64 data
}
ByteBlock::init(ty<i32> , data<u64>){
    this.type = ty
    this.data = data
}
mem Sym {
    string.String* segName
    string.String* name
    i32  externed
    i32  addr
    std.Array*      datas # ByteBlock*
    string.String*  str
    i8*             bin_ptr
    i32             bin_len

    i32             global
    i32             isstr
    i32             isbin
    i32             isrel
}
func newSym(name<string.String>, externed<i32>)
{
    utils.debug("newSym: name:%S externed:%d".(i8),name.str(),externed)
    s<Sym> = new Sym {
        segName : string.S(".text".(i8)),
        name : name,
        addr : 0,
        datas : std.NewArray(),
        externed : externed,
        isstr : false,
        isbin : false,
        isrel : false
    }
    if externed {
        s.segName = string.emptyS()
    }
    return s
}
func newStringSym(name<string.String>, str<string.String>,pos<i32>)
{
    utils.debug("newStringSym: name:%S %S pos:%d".(i8),name.str(),str.str(),pos)
    return new Sym {
        segName : string.S(".data".(i8)),
        name : name,
        addr : pos,
        datas : std.NewArray(),
        externed : false,
        isstr : true,
        isbin : false,
        isrel : false,
        global: false,
        str : str
    }
}
// Raw .incbin bytes (pointer + length; may contain interior NULs).
func newBinSym(name<string.String>, ptr<i8*>, len<i32>, pos<i32>)
{
    return new Sym {
        segName : string.S(".data".(i8)),
        name : name,
        addr : pos,
        datas : std.NewArray(),
        externed : false,
        isstr : false,
        isbin : true,
        isrel : false,
        global: false,
        bin_ptr : ptr,
        bin_len : len
    }
}
func newDataSym(name<string.String>,pos<i32>)
{
    utils.debug("newDataSym: name:%S pos:%d".(i8),name.str(),pos)
    return new Sym {
        name : name,
        global : false,
        addr : pos,
        isstr : false,
        isbin : false,
        isrel : false,
        segName : string.S(".data".(i8)),
        externed : false,
        datas : std.NewArray(),
    }
}
Sym::addBlock(b<ByteBlock>){
    this.datas.push(b)
}
