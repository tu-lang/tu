use asmer.parser
use std
use string 

mem ModRM
{
    i32 mod//0-1
    i32 reg//2-4
    i32 rm//5-7
}
ModRM::init(){
    this.mod = -1
    this.reg = 0
    this.rm  = 0
}
mem SIB
{
    i32 scale//0-1
    i32 index//2-4
    i32 base//5-7
}
SIB::init(){
    this.scale = -1
    this.index = 0
    this.base  = 0
}
mem Inst
{
    i32 disp
    u64 imm
    i32 negative
    i32 dispLen
}
Inst::init() {
    this.disp = 0
    this.dispLen = 0
    this.imm = 0
    this.negative = false
}
Inst::setDisp(d<i32>,len<i32>)
{
    this.dispLen = len
    this.disp    = d
}

mem Instruct {
    string.String* name
    string.String* str
    std.Array*     tks //Token,
    i32        is_rel
    i32        is_func
    i32        type
    i32        regnum
    i32   left
    i32   right
    Inst*       inst
    SIB*        sib
    ModRM*      modrm
    i32         has16bits
    parser.Parser*  parser

    u8          bytes[20]
    i32         size
    i32         line
    i32         column
}
Instruct::init(type<i32>,p<parser.Parser>)
{
    this.str        = string.emptyS()
    this.name       = string.emptyS()
    this.tks        = std.NewArray()
    this.is_rel     = false
    this.is_func    = false
    this.type       = type
    this.left       = ast.TY_INVAL
    this.right      = ast.TY_INVAL
    this.regnum     = 0

    this.has16bits = false

    //init
    this.modrm = new ModRM()
    this.sib   = new SIB()
    this.inst  = new Inst()
    this.parser = p
    //inmems
    this.size  = 0
    //debug
    this.line = p.scanner.line
    this.column = p.scanner.column
}