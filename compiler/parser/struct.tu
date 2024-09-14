use string
use std
use compiler.ast
use compiler.parser.scanner
use compiler.utils
use compiler.gen
use compiler.compile

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
	reader<scanner.ScannerStatic> = this.scanner
	this.check(reader.curToken == ast.MEM,"parse struct define, tok not mem")
	reader.scan()
	//must VAR
	this.check(reader.curToken == ast.VAR,"parse struct define,tok not var")
	s = new ast.Struct()
	s.parser = this
	s.name  = reader.curLex.dyn()
	this.check(utils.isUpper(s.name),"first char of class name need be Upper")
	s.pkg   = this.pkg.package
	reader.scan()
	if ( reader.curToken != ast.LBRACE ){
		this.check(reader.curToken == ast.COLON)
		//eat :
		reader.scan()
		//must var
		this.check(reader.curToken == ast.VAR)
		cl = reader.curLex.dyn()
		if (cl == "pack" ){
			s.ispacked = true
		}
		//eat var
		reader.scan()
	}
	//must {
	this.check(reader.curToken == ast.LBRACE)
	reader.scan()
	//end for }
	idx = 0
	while(reader.curToken != ast.RBRACE)
	{
		if(reader.curToken == ast.VAR){
			//TODO: &idx
            this.parseMembers(s,idx,true)
        }else{
            if(!this.isbase())
                this.check(false,"should be i8-u64 type in struct member define")
            this.parseMembers(s,idx,false)
        }
	}
	// s.compute()
	if compile.phase == compile.GlobalPhase && this.pkg.structs[s.name] != null {
		this.check(false,"already define " + s.name)
	}
	this.pkg.addStruct(s.name,s)
	//eat }
	reader.scan()
}

Parser::genAsyncPollMember(s , idx){
	member = new ast.Member()
	tk = ast.I64
    member.line = this.line
    member.column = this.column
    member.file  = this.filepath
    member.isunsigned = ast.type_isunsigned(tk)
    member.type = tk
    member.size = typesize[int(tk)]
    member.align = typesize[int(tk)]
    member.arrsize = 1
    member.arrvar = null
    member.idx = idx
	idx += 1
    member.name = "poll.f"

	s.member[] = member
}

Parser::parseMembers(s ,idx ,isstruct){
	reader<scanner.ScannerStatic> = this.scanner
	utils.debug("Parser::parseMembers ")
	member = new ast.Member()
	tk = reader.curToken
    if(isstruct){
        this.expect(ast.VAR,"expect var token in struct member define")
        structname = reader.curLex.dyn() 
        structpkg  = this.pkg.package
        reader.scan()
        if(reader.curToken == ast.DOT){
            reader.scan()
            this.check(reader.curToken == ast.VAR)
            structpkg  = structname
            structname = reader.curLex.dyn()
            reader.scan()
        }
        member.structpkg = structpkg
        member.structname = structname
        member.isstruct = true
        member.structref = null

        tk = ast.U64
    }else {
        if(!this.isbase()) this.check(false,"should be base i8-u64 field define")
        reader.scan()
    }
    if(reader.curToken == ast.MUL){
        member.align = 8
        member.pointer = true
        reader.scan()
    }
    this.check(tk >= ast.I8 && tk <= ast.F64,"member type only support i8 - u64")
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
        this.check(reader.curToken == ast.VAR,"should be var in struct field define")
        field.name = reader.curLex.dyn()

        reader.scan()
        if(reader.curToken == ast.COLON && !isstruct){
            reader.scan()
            this.check(reader.curToken == ast.INT,"should be number in struct field define")
            field.bitfield = true
            field.bitwidth = string.tonumber(reader.curLex.dyn())
            reader.scan()
        }else if(reader.curToken == ast.LBRACKET){ 
            field.isarr   = true
            reader.scan()
            field.arrvar = this.parseExpression(1)
            this.check(reader.curToken == ast.RBRACKET,"should be ] at last struct member arr parse")
            reader.scan()
        }
        s.member[] = field
        if(reader.curToken == ast.COMMA){
            reader.scan()
            continue
        }
        break
    }
}

Parser::parseStructInit(pkgname,name){
	reader<scanner.ScannerStatic> = this.scanner
	init = new gen.StructInitExpr(this.line,this.column)
	init.pkgname = pkgname
	init.name    = name
	this.expect(ast.LBRACE)//{
	reader.scan()//eat {
	while(reader.curToken != ast.RBRACE){
		this.expect(ast.VAR)
		fieldname = reader.curLex.dyn()

		this.next_expect(ast.COLON) 
		reader.scan()//eat :

		fieldvalue = this.parseExpression(1)
		if(fieldvalue == null) this.panic(" field value is null in struct init")


		match reader.curToken {
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
		if(reader.curToken == ast.COMMA)
			reader.scan()

		init.fields[fieldname] = fieldvalue
	}
	//eat }
	reader.scan()

	return init
}