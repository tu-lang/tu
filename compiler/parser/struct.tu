use string
use std
use compiler.ast
use compiler.parser.scanner
use compiler.utils
use compiler.gen

Parser::parseStructDef()
{
	// struct header
	// {
	// 	i8   a
	// 	i16  b
	// 	i32  c:20
	// 	i32  c:12
	// 	u64  d
	// }
	utils.debug("found struct start parser..")
	this.check(this.scanner.curToken == ast.MEM,"parse struct define, tok not mem")
	this.scanner.scan()
	//must VAR
	this.check(this.scanner.curToken == ast.VAR,"parse struct define,tok not var")
	s = new ast.Struct()
	s.parser = this
	s.name  = this.scanner.curLex
	this.check(utils.isUpper(s.name),"first char of class name need be Upper")
	s.pkg   = this.pkg.package
	this.scanner.scan()
	if ( this.scanner.curToken != ast.LBRACE ){
		this.check(this.scanner.curToken == ast.COLON)
		//eat :
		this.scanner.scan()
		//must var
		this.check(this.scanner.curToken == ast.VAR)
		if (this.scanner.curLex == "pack" ){
			s.ispacked = true
		}
		//eat var
		this.scanner.scan()
	}
	//must {
	this.check(this.scanner.curToken == ast.LBRACE)
	this.scanner.scan()
	//end for }
	idx = 0
	while(this.scanner.curToken != ast.RBRACE)
	{
		if(this.scanner.curToken == ast.VAR){
			//TODO: &idx
            this.parseMembers(s,idx,true)
        }else{
            if(!this.isbase())
                this.check(false,"should be i8-u64 type in struct member define")
            this.parseMembers(s,idx,false)
        }
	}
	// s.compute()
	this.pkg.addStruct(s.name,s)
	//eat }
	this.scanner.scan()
}
Parser::parseMembers(s ,idx ,isstruct){
	member = new ast.Member()
	tk = this.scanner.curToken
    if(isstruct){
        this.expect(ast.VAR,"expect var token in struct member define")
        structname = this.scanner.curLex 
        structpkg  = this.pkg.package
        this.scanner.scan()
        if(this.scanner.curToken == ast.DOT){
            this.scanner.scan()
            this.check(this.scanner.curToken == ast.VAR)
            structpkg  = structname
            structname = this.scanner.curLex
            this.scanner.scan()
        }
        member.structpkg = structpkg
        member.structname = structname
        member.isstruct = true
        member.structref = null

        tk = ast.U64
    }else {
        if(!this.isbase()) this.check(false,"should be base i8-u64 field define")
        this.scanner.scan()
    }
    if(this.scanner.curToken == ast.MUL){
        member.align = 8
        member.pointer = true
        this.scanner.scan()
    }
    this.check(tk >= ast.I8 && tk <= ast.U64,"member type only support i8 - u64")
    member.line = this.line
    member.column = this.column
    member.file  = this.filepath
    member.isunsigned = ast.type_isunsigned(tk)
    member.type = tk
    member.size = typesize[int(tk)] 
    member.align = typesize[int(tk)]
    member.arrsize = 1    
    member.arrvar = null
	loop {
        field = member.clone()
        field.idx    = idx 
		idx += 1
        this.check(this.scanner.curToken == ast.VAR,"should be var in struct field define")
        field.name = this.scanner.curLex

        this.scanner.scan()
        if(this.scanner.curToken == ast.COLON && !isstruct){
            this.scanner.scan()
            this.check(this.scanner.curToken == ast.INT,"should be number in struct field define")
            field.bitfield = true
            field.bitwidth = string.tonumber(this.scanner.curLex)
            this.scanner.scan()
        }else if(this.scanner.curToken == ast.LBRACKET){ 
            field.isarr   = true
            this.scanner.scan()
            field.arrvar = this.parseExpression(1)
            this.check(this.scanner.curToken == ast.RBRACKET,"should be ] at last struct member arr parse")
            this.scanner.scan()
        }
        s.member[] = field
        if(this.scanner.curToken == ast.COMMA){
            this.scanner.scan()
            continue
        }
        break
    }
}
Parser::parseStructInit(pkgname,name){
	init = new gen.StructInitExpr(this.line,this.column)
	init.pkgname = pkgname
	init.name    = name
	this.expect(ast.LBRACE)//{
	this.scanner.scan()//eat {
	while(this.scanner.curToken != ast.RBRACE){
		this.expect(ast.VAR)
		fieldname = this.scanner.curLex

		this.next_expect(ast.COLON) //解析:
		this.scanner.scan()//eat :

		fieldvalue = this.parseExpression(1)
		if(fieldvalue == null) this.panic(" field value is null in struct init")


		match this.scanner.curToken {
			ast.RBRACE | ast.COMMA : {}
			ast.LBRACE : {
				if type(fieldvalue) != type(gen.VarExpr) this.panic(
					fieldvalue.toString("") + " \ninvlaid in struct init"
				)
				var = fieldvalue
				fieldvalue = this.parseStructInit(var.package,var.varname)
			}
			_: {
				this.panic("file value is invalid in struct init")
			}
		}
		if(this.scanner.curToken == ast.COMMA)
			this.scanner.scan()

		init.fields[fieldname] = fieldvalue
	}
	//eat }
	this.scanner.scan()

	return init
}