use ast
use utils
use parser
use string

Instruct::instheads(){
    utils.debug("Instruct::instheads()".(i8))
    if(this.type == ast.KW_PUSH) return true

    if(this.type == ast.KW_CALL){
        if(ast.r8ishigh(this.tks.addr[0]))
            this.append1(0x41.(i8))
        return true
    }
    if(ast.r8ishigh(this.tks.addr[0])){
        if(this.type == ast.KW_POP) {
            this.append1(0x41.(i8))
            return true
        }
        this.append1(0x49.(i8))
    }else if(ast.r8islow(this.tks.addr[0])){
        if(this.type == ast.KW_POP) return true
        this.append1(0x48.(i8))
    }
}
Instruct::genOneInst() {
    utils.debug("Instruct::genOneInst()".(i8))
    len<i32>  = 4 
    exchar<i8> = 0
    opcode<u16> = opcode1[this.type - ast.KW_CALL]
    if ( (this.tks.addr[0] >= ast.KW_AL) && (this.tks.addr[0] <= ast.KW_BH) ){
        opcode = opcode1_8[this.type - ast.KW_CALL]
    }
    this.instheads()

    if(this.type == ast.KW_CALL || this.type >= ast.KW_JMP && this.type <= ast.KW_JNA)
    {
        match this.type {
            ast.KW_CALL:{
                if this.left == ast.TY_REG {
                    opcode = 0xff
                    this.append1(opcode)

                    exchar = 0xd0 + this.modrm.reg
                    this.append1(exchar)
                    return true
                }
            }
            ast.KW_JMP | ast.KW_JE | ast.KW_JG | ast.KW_JL | ast.KW_JLE | ast.KW_JNE | ast.KW_JNA : {
                sym<ast.Sym> = this.parser.symtable.getSym(this.name)
                rel<i32> = 0
                if sym.externed { 
                    opcode = opcode1_extern[this.type - ast.KW_CALL]
                    this.append1(opcode)
                    len = 4
                }else{
                    len = 1
                    if(this.type != ast.KW_CALL ){
                        opcode = opcode1_extern[this.type - ast.KW_CALL]
                        len = 4
                        if(this.type == ast.KW_JMP)
                            this.append1(opcode)
                        else
                            this.append2(opcode)
                    }else{
                        this.append1(opcode)
                    }
                    if(this.type == ast.KW_CALL) len = 4
                    rel = sym.addr - this.parser.text_size - len
                }
                this.updateRel()
                this.append(rel,len)
                return true
            }
            _ :{
                this.check(False,"unknown inst in oneinst:")
                this.append1(opcode >> 8)
                this.append1(opcode)
            }
        }
        is_rel<i32> = this.updateRel()
        rel<i32>  = this.inst.imm - (this.parser.text_size + 4)
        if(this.left == ast.TY_IMMED && this.inst.imm == 0){
            sym<ast.Sym> = this.parser.symtable.getSym(this.name)
            rel = sym.addr - this.parser.text_size - 1
            if(!is_rel && this.type != ast.KW_CALL){
                len = 1
            }
            this.append(rel,len)
            return true
        }
        if(is_rel){
            this.append(0.(i8),len)
            return true
        }
        this.append(rel,len)
    }
    else if(this.type == ast.KW_INT)
    {
        this.append1(opcode)
        this.append(this.inst.imm,1)
    }
    else if(this.type == ast.KW_NOT){
        exchar = 0xd0
        exchar += this.modrm.reg
        this.append1(opcode)
        this.append1(exchar)
    }
    else if(this.type == ast.KW_PUSH)
    {
        if(this.left == ast.TY_IMMED)
        {
            if(this.inst.imm > I8_MAX){
                opcode = 0x68
                len = 4
            }else{
                opcode = 0x6a
                len = 1
            }
            this.append1(opcode)
            this.append(this.inst.imm,len)
        }
        else if(this.tks.addr[0] < ast.KW_R8)
        {
            opcode += this.modrm.reg
            this.append1(opcode)
        }else{
            this.append1(0x41.(i8))
            opcode += this.modrm.reg
            this.append1(opcode)
        }
    }
    else if(this.type == ast.KW_SETL || this.type ==ast.KW_SETLE || this.type == ast.KW_SETE || 
            this.type == ast.KW_SETGE || this.type == ast.KW_SETBE||this.type == ast.KW_SETG ||this.type == ast.KW_SETNE ||this.type == ast.KW_SETB){
        this.append2(opcode)
        exchar = 0xc0
        exchar += this.modrm.reg
        this.append1(exchar)
    }
    else if(this.type == ast.KW_DIV || this.type == ast.KW_IDIV){
        //div  && idiv
        exchar = 0xf0
        if(this.type == ast.KW_IDIV)
            exchar = 0xf8
        exchar += this.modrm.reg
        this.append1(opcode)
        this.append1(exchar)
    }
    else if(this.type == ast.KW_INC || this.type == ast.KW_DEC || this.type == ast.KW_NEG )
    {
        this.check(False,"unsupport instruct in inc dec neg div")
    }
    else if(this.type == ast.KW_POP)
    {
        if(this.left == ast.TY_MEM){
            opcode = 0x8f
            this.append1(opcode)
            this.writeModRM()
            if(this.modrm.rm == 4)
                this.writeSIB()
            if(this.inst.dispLen)
                this.append(this.inst.disp,this.inst.dispLen)
        }else{
            opcode += this.modrm.reg
            this.append(opcode,1)
        }
    }else{
        this.check(False,"unkown inst in genone")
    }

}
