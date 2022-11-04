use string
use std
use ast
use parser.scanner
use utils
use gen

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
	s.pkg   = this.package
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
		tk  = this.scanner.curToken
		if(tk == ast.VAR){
			lex = this.scanner.curLex 
			member = new ast.Member()
			member.isunsigned = true
			member.isstruct   = true
			member.structpkg  = this.pkg.package
			member.structname = lex
			member.structref  = null
			member.arrsize    = 1
			//debug
			member.line = this.line
			member.column = this.column
			member.file   = this.filepath

			this.scanner.scan()
			if(this.scanner.curToken == ast.DOT){
				this.scanner.scan()
				this.check(this.scanner.curToken == ast.VAR)
				member.structpkg = member.structname
				member.structname = this.scanner.curLex
				this.scanner.scan()
			}
			if(this.scanner.curToken == ast.MUL){
				member.pointer = true
				this.scanner.scan()
			}
			this.check(this.scanner.curToken == ast.VAR)
			member.name = this.scanner.curLex
			s.member[] = member
			this.scanner.scan()
			continue
		}
		this.scanner.scan()
		pointer = false
		if(this.scanner.curToken == ast.MUL){
			pointer = true
			this.scanner.scan()
		}
		member = this.parseMember(tk,idx,pointer)
		s.member[] = member
		while(this.scanner.curToken == ast.COMMA){
			//eat ,
			this.scanner.scan()
			member = this.parseMember(tk,idx,pointer)
			s.member[] = member
		}
	}
	// s.compute()
	this.pkg.addStruct(s.name,s)
	//eat }
	this.scanner.scan()
}
Parser::parseMember(tk,idx,pointer){
	this.check(tk >= ast.I8 && tk <= ast.U64)
	member = new ast.Member()
	//debug
	member.line = this.line
	member.column = this.column
	member.file  = this.filepath
	member.isunsigned = ast.type_isunsigned(tk)
	member.idx    = idx
	idx += 1
	member.type = tk
	member.size = typesize[int(tk)]
	member.align = typesize[int(tk)]
	member.arrsize = 1

	if pointer {
		member.align = 8
		member.pointer = true
	}

	this.check(this.scanner.curToken == ast.VAR)
	member.name = this.scanner.curLex

	this.scanner.scan()
	if(this.scanner.curToken == ast.COLON){
		this.scanner.scan()
		this.check(this.scanner.curToken == ast.INT)
		member.bitfield = true
		member.bitwidth = string.tonumber(this.scanner.curLex)
		this.scanner.scan()
	}else if(this.scanner.curToken == ast.LBRACKET){
		this.scanner.scan()
		this.check(this.scanner.curToken == ast.INT)
		member.isarr   = true
		member.arrsize = string.tonumber(this.scanner.curLex)
		this.scanner.scan()
		this.check(this.scanner.curToken == ast.RBRACKET)
		this.scanner.scan()
	}
	return member
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

		fieldvalue = this.parseExpression()
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