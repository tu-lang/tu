use ast
use utils
use instruct
use string

Parser::parseFunction(labelname<string.String>) {
    utils.debug("Parser::parseFunction(%S)".(i8),labelname.str())
    this.check(this.scanner.curtoken >= ast.KW_MOV && this.scanner.curtoken <= ast.KW_CDQ,"should be any valid inst [mov-ret]")

    fc<ast.Function> = new ast.Function(labelname)

    inst<instruct.Instruct> = null
    loop {

        token<i32> = this.scanner.curtoken

        if( token >= ast.KW_MOV && token <= ast.KW_LEA )
            inst  = this.parseTwoInstruct()
        else if( token >= ast.KW_CALL && token <= ast.KW_POP )
            inst  = this.parseOneInstruct()
        else if(token >= ast.KW_RET && token <= ast.KW_CDQ)
            inst  = this.parseZeroInstruct()
        else
            utils.error("[Parser] unknow instruct:%s\n",this.scanner.curlex)

        fc.instructs.push(inst)

        if(this.scanner.curtoken >= ast.KW_MOV && this.scanner.curtoken <= ast.KW_CDQ){} else{
            break
        }
    }

    return fc
}
