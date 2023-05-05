use asmer
use ast
use utils
use instruct

Instruct::genZeroInst() {
    utils.debug("Instruct::genZeroInst()".(i8))
    i<i32> = this.type - ast.KW_RET
    opcode<u16> = opcode0[i]
    if(this.type == ast.KW_CQO)
        this.append1(0x48.(i8))
    if(this.need2byte_op2())
        this.append2(opcode)
    else 
        this.append1(opcode)
}
Instruct::gen(){
    utils.debug("Instruct::gen".(i8))
    token<i32> = this.type
    if( token >= ast.KW_MOV && token <= ast.KW_LEA )
        this.genTwoInst()
    else if( token >= ast.KW_CALL && token <= ast.KW_POP )
        this.genOneInst()
    else if(token >= ast.KW_RET && token <= ast.KW_CDQ)
        this.genZeroInst()
    else
        utils.error(*"[instruct gen] unknow instuct\n")
    utils.debug("Instruct::gen done %S".(i8),this.str.str())
}
