use asmer.ast
use asmer.utils
use asmer.instruct
use std
use string
use fmt
use os

Parser::regoffset(){
    ty<i32> = this.scanner.curtoken
    if(ty >= ast.KW_RAX && ty < ast.KW_R8)
            return ty - ast.KW_RAX
    if(ty >= ast.KW_EAX && ty <= ast.KW_EDI)
        return ty - ast.KW_EAX
    if(ty >= ast.KW_AL && ty <= ast.KW_BH){
        exp<i32> = ast.reglen(ty)
        return ty - ast.KW_AL - (1 - exp%4) * 8
    }
    if(ty >= ast.KW_R8 && ty <= ast.KW_R10)
        return ty - ast.KW_R8
    utils.errorf("regoffset invalid :%d",int(ty))
}
Parser::parseInstruct(inst<instruct.Instruct>) {
    utils.debug("Parser::parseInstruct() %S".(i8),this.scanner.curlex.str())
    name<string.String> = null
    sym<ast.Sym>  = null

    inst.str.cat(this.scanner.curlex) 
    tk<i32> = this.scanner.scan()
    match tk {
        ast.TK_IMME:{
            number<u64>   = 0

            inst.str.cat(this.scanner.curlex)
            //next
            this.scanner.scan()
            match this.scanner.curtoken {
                //get number
                ast.TK_NUMBER: {
                    prs<string.String> = this.scanner.curlex.sub(0.(i8),2.(i8))
                    if prs.cmpstr(*"0x") == string.Equal {
                        number = std.strtoul(this.scanner.curlex.inner,0.(i8),16.(i8))
                    }else{
                        if(this.scanner.curlex.inner[0] == '-'){
                            inst.inst.negative = true
                            number = std.strtol(this.scanner.curlex.inner,0.(i8),10.(i8))
                        }else
                            number = std.strtoul(this.scanner.curlex.inner,0.(i8),10.(i8))
                    }
                }
                ast.TK_SUB: {
                    //get -
                    //should be number
                    inst.inst.negative = true
                    this.check(this.scanner.scan() == ast.TK_NUMBER,"should be -number")
                    number   = std.strtol(this.scanner.curlex.inner,0.(i8),10.(i8))
                    number   = 0 - number
                }
                _ : utils.error(
                        "[Parser] should be number at but got instruct:%s\n", this.scanner.curlex.dyn()
                    )
            }
            inst.tks.push(this.scanner.curtoken)
            inst.inst.imm = number
            inst.str.cat(this.scanner.curlex)
            //next one
            this.scanner.scan()
            return ast.TY_IMMED
        }
        ast.KW_LABEL:{
            //label name
            name<string.String> = this.scanner.curlex.dup()
            inst.is_rel        = true
            //next one
            inst.str.cat(this.scanner.curlex)
            if(this.scanner.scan() == ast.TK_AT){
                this.check(False,"unsupport GOTPCREL")
                inst.is_func = true
                inst.is_rel  = true
                //next one shuould be GOTPCREL
                inst.str.cat(this.scanner.curlex)
                this.check(this.scanner.scan() == ast.KW_LABEL,"should be :")
                //next one
                inst.str.cat(this.scanner.curlex)
                this.scanner.scan()
            }
            if(this.scanner.curtoken == ast.TK_LPAREN){
                inst.is_rel  = true
                //shoulde be %rip
                inst.str.cat(this.scanner.curlex)
                this.check(this.scanner.scan() == ast.KW_RIP,"should be rip")
                inst.tks.push(ast.KW_RIP)
                //shoulde be )
                inst.str.cat(this.scanner.curlex)
                this.check(this.scanner.scan() == ast.TK_RPAREN,"should be )")

                //next one
                inst.str.cat(this.scanner.curlex)
                this.scanner.scan()
            }else{
                inst.tks.push(ast.KW_LABEL)
            }

            sym<ast.Sym> = this.symtable.getSym(name)
            inst.inst.imm = sym.addr
            inst.name = name

            return ast.TY_IMMED
        }
        ast.TK_SUB | ast.TK_NUMBER:{
            num<i32> = 0
            if(this.scanner.curtoken == ast.TK_SUB){
                inst.str.cat(this.scanner.curlex)
                this.check(this.scanner.scan() == ast.TK_NUMBER,"should be number in -(expr)")
                num -= std.strtol(this.scanner.curlex.str(),0.(i8),10.(i8))
            }else{
                num = std.strtol(this.scanner.curlex.str(),0.(i8),10.(i8))
            }
            inst.str.cat(this.scanner.curlex)
            this.check(this.scanner.scan() == ast.TK_LPAREN,"should be (")
            inst.str.cat(this.scanner.curlex)
            this.scanner.scan()
            this.check(this.scanner.curtoken >= ast.KW_RAX && this.scanner.curtoken <= ast.KW_RIP,"should be any valid register")
            if( num >= -128 && num < 128)//disp8
            {
                inst.modrm.mod = 1
                inst.inst.setDisp(num,1.(i8))
            }else{
                //mod: 1 0 
                inst.modrm.mod = 2
                inst.inst.setDisp(num,4.(i8))
            }
            inst.modrm.rm = this.regoffset()
            if( this.scanner.curtoken == ast.KW_RSP)//sib
            {
                inst.modrm.rm  = 4//rm = 4
                inst.sib.scale = 0
                inst.sib.index = 4
                inst.sib.base  = 4
            }
            inst.tks.push(this.scanner.curtoken)
            //next one
            inst.str.cat(this.scanner.curlex)
            this.check(this.scanner.scan() == ast.TK_RPAREN,"should be )")
            inst.str.cat(this.scanner.curlex)
            this.scanner.scan()
            return ast.TY_MEM
        }
        ast.TK_LPAREN:{
            inst.str.cat(this.scanner.curlex)
            tk<i32> = this.scanner.scan()
            match tk {
                ast.KW_RSP: {
                    inst.modrm.mod = 0
                    inst.modrm.rm  = 4
                    inst.sib.scale = 0
                    inst.sib.index = 4
                    inst.sib.base  = 4
                }
                ast.KW_RBP:{
                    inst.modrm.mod = 1
                    inst.modrm.rm  = 5
                    inst.inst.setDisp(0.(i8),1.(i8))
                }
                _ :{
                    inst.modrm.mod = 0
                    inst.modrm.rm  = this.regoffset()
                    this.check(this.scanner.curtoken >= ast.KW_EAX && this.scanner.curtoken <= ast.KW_RIP,"should be any register in default1")
                }
            }
            inst.tks.push(this.scanner.curtoken)
            //eat )
            inst.str.cat(this.scanner.curlex)
            this.check(this.scanner.scan() == ast.TK_RPAREN,"should be ) in ()")
            //next one
            inst.str.cat(this.scanner.curlex)
            this.scanner.scan()
            return ast.TY_MEM
        }
        _: {
            //maybe call *%rax
            if this.scanner.curtoken == ast.TK_MUL {
                //eat *
                inst.str.cat(this.scanner.curlex)
                this.scanner.scan()
            }
            this.check(
                (this.scanner.curtoken >= ast.KW_RAX && this.scanner.curtoken <= ast.KW_RIP) ||
                (this.scanner.curtoken >= ast.KW_AL && this.scanner.curtoken <= ast.KW_BH) ||
                (this.scanner.curtoken >= ast.KW_EAX && this.scanner.curtoken <= ast.KW_EDI),
                "should be any register in default"
            )
            inst.tks.push(this.scanner.curtoken)
            if(this.scanner.curlex.cmpstr(*"%ax") == string.Equal)
                inst.has16bits = true

            if (inst.regnum)
            {
                inst.modrm.mod = 3
                inst.modrm.rm = inst.modrm.reg
                if(ast.isr8(this.scanner.curtoken)){
                    if(ast.isr1(inst.tks.addr[0]) || ast.isr4(inst.tks.addr[0]) || inst.type == ast.KW_MUL){
                        inst.modrm.reg = this.regoffset()
                    }else{
                        inst.modrm.rm = this.regoffset()
                    }
                }else if(ast.isr4(this.scanner.curtoken)){
                    if(ast.isr1(inst.tks.addr[0]) || inst.type == ast.KW_MUL){
                        inst.modrm.reg = this.regoffset()
                    }else{
                        inst.modrm.rm = this.regoffset()
                    }
                }else{
                    if(inst.type == ast.KW_SHL || inst.type ==ast.KW_SHR)
                        inst.modrm.reg  = this.regoffset()
                    else
                        inst.modrm.rm  = this.regoffset()
                }
            } else
            {
                inst.modrm.reg = this.regoffset()
            }
            inst.regnum += 1

            //next one
            inst.str.cat(this.scanner.curlex)
            this.scanner.scan()
            return ast.TY_REG
        }
    }
}
Parser::parseTwoInstruct() {
    this.check(this.scanner.curtoken >= ast.KW_MOV && this.scanner.curtoken <= ast.KW_LEA ,"should be in [mov-lea] register")
    inst<instruct.Instruct> = new instruct.Instruct(this.scanner.curtoken,this)
    inst.left      = this.parseInstruct(inst)
    this.check(this.scanner.curtoken == ast.TK_COMMA,"should be ,in two inst")
    //eat ,
    inst.right     = this.parseInstruct(inst)
    return inst
}
Parser::parseOneInstruct() {
    inst<instruct.Instruct> = new instruct.Instruct(this.scanner.curtoken,this)
    inst.left      = this.parseInstruct(inst)
    return inst
}
Parser::parseZeroInstruct() {
    inst<instruct.Instruct> = new instruct.Instruct(this.scanner.curtoken,this)
    //eat ret
    inst.str = this.scanner.curlex
    this.scanner.scan()
    return inst
}