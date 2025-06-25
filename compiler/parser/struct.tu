use string
use std
use compiler.ast
use compiler.parser.scanner
use compiler.utils
use compiler.gen
use compiler.compile

Parser::parseApiDef()
{
    // api header {
    // fn test() (i32)
    // fn test2() {
    // }
    // }
    utils.debug("found api start parser..")
	reader<scanner.ScannerStatic> = this.scanner
    this.check(reader.curToken == ast.API,"parse api define, tok not mem")
    reader.scan()
    //must VAR
    this.check(reader.curToken == ast.VAR,"parse api define,tok not var")
	s = new ast.Struct()
    s.isapi = true
    s.parser = this
    s.name  = reader.curLex.dyn()

    // s.compute()
    if compile.phase == compile.GlobalPhase && std.exist(s.name,this.pkg.structs){
        this.check(false,"already define " + s.name)
    }

    if compile.phase != compile.GlobalPhase {
        s = this.pkg.getStruct(s.name)
		s.member = []
    }
    this.check(utils.isUpper(s.name),"first char of class name need be Upper")
    s.pkg   = this.pkg.package
    reader.scan()
    this.check(reader.curToken == ast.LBRACE,"api can't define struct propertiy")
    reader.scan()
    //end for }
	idx = 0
    while reader.curToken != ast.RBRACE {
        this.ctx = new ast.Context()
		fc = this.parseFuncDef(ast.StructFunc,s,null,false)
        fc.vid = idx
        idx   += 1
        this.ctx = null

        this.check(fc != null)
        this.pkg.addStructFunc(s.name,fc.name,fc,s)
        this.addFunc(s.name + fc.name,fc)
    }

    //RFC021:
    if compile.phase == compile.GlobalPhase {
        this.pkg.addStruct(s.name,s)
        this.structs[s.name] = s
    }
    //eat }
    reader.scan()
}

Parser::parseApiImpl()
{
    utils.debug("found api impl start parser..")
	reader<scanner.ScannerStatic> = this.scanner
    this.check(reader.curToken == ast.IMPL,"parse api impl, tok not mem")
    reader.scan()
    //must VAR
    this.check(reader.curToken == ast.VAR,"parse api impl,tok not var")
	apiPkg  = ""
	apiName = reader.curLex.dyn()
    //eat
    reader.scan()
    if reader.curToken == ast.DOT {
        reader.scan()
        this.check(reader.curToken == ast.VAR,"should be impl name")
        apiPkg = apiName
        apiName = reader.curLex.dyn()
        //eat
        reader.scan()
    }
    this.check(reader.curToken == ast.FOR, "should be for in impl statement")
    reader.scan()
    this.check(reader.curToken == ast.VAR)
    //eat
    implName = reader.curLex.dyn()
    reader.scan()
    this.check(reader.curToken == ast.LBRACE,"neq {")
    //eat {
    reader.scan()

	apiDef = null
	implDef = null
    this.pkg.impls[implName] = true

	fctype = ast.ClassFunc
    if compile.phase != compile.GlobalPhase {
        apiDef = package.getStruct(apiPkg,apiName)
        this.check(apiDef != null,"api not define")
        this.check(apiDef.isapi,"must be api:" + apiDef.name)
        implDef = package.getStruct("",implName)
        this.check(implDef != null,"impl struct not define")
        //RFC105:
        if implDef.isasync 
            this.check(false,"async struct can't impl api Temporarily")
        fctype = ast.StructFunc
    }
    //end for }
	idx = 0
	impls = {}
    while reader.curToken != ast.RBRACE {
        this.ctx = new ast.Context()
		fc = this.parseFuncDef(fctype, implDef, null, false)
        this.ctx = null

        this.check(fc != null)
        if fctype == ast.StructFunc
            this.pkg.addStructFunc(implName,fc.name,fc,implDef)
        impls[fc.name] = fc
        this.addFunc(implName + fc.name,fc)
    }

    if compile.phase == compile.FunctionPhase {
        apiImpl = new ast.ApiImpl()
        apiImpl.name = apiName
        for iter : apiDef.order_funcs {
            if std.exist(iter.name ,impls) {
                implFunc = impls[iter.name]
                this.checkImplSig(iter,implFunc)
                apiImpl.funcs[] = implFunc
            }else{
                if !iter.hasBlock
                    this.check(false,"API not impl default func, need impl it")
                apiImpl.funcs[] = iter
                if implDef.getFunc(iter.name) != null
                    this.check(false,implDef.name +":api func conflict with struct impl:"+iter.name)
                this.pkg.addStructFunc(implName,iter.name,iter,implDef)
            }
        }
        implDef.apis[] = apiImpl
    }
    //eat }
    reader.scan()
}

Parser::checkImplSig(dFunc , iFunc){
    if std.len(dFunc.params_order_var) != std.len(iFunc.params_order_var) {
        this.check(false,"impl functions params not consistent")
    }

    for i  = 1 ; i < std.len(dFunc.params_order_var) ; i += 1 {
        dVar = dFunc.params_order_var[i]
        iVar = iFunc.params_order_var[i]
        if dVar.structtype {
            if dVar.structname != "" && dVar.structname != null {
                if dVar.structname != iVar.structname
                    iVar.check(false,"var type should eq with api param")
            }else{
                dty<i32> = dVar.type
                if dty != iVar.type
                    iVar.check(false,"var type should eq with api param")
            }
        }

    }
}

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
	if compile.phase != compile.GlobalPhase {
		s = this.pkg.getStruct(s.name)
		s.member = []
	}

	this.check(utils.isUpper(s.name),"first char of class name need be Upper")
	s.pkg   = this.pkg.package
	reader.scan()
	if ( reader.curToken != ast.LBRACE ){
		this.check(reader.curToken == ast.COLON)
		//eat :
		reader.scan()
		//must var
		// this.check(reader.curToken == ast.VAR)
		cl = reader.curLex.dyn()
		if cl == "pack" {
			s.ispacked = true
		} else if cl == "async" {
			s.isasync = true
		}else {
			this.check(false,"should be pack or async")
		}
		//eat var
		reader.scan()
	}
	//must {
	this.check(reader.curToken == ast.LBRACE)
	reader.scan()
	//end for }
	idx = 0
	if s.isasync || std.exist(s.name,this.pkg.impls) {
		this.genAsyncPollMember(s,idx)
	}
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

	if compile.phase == compile.GlobalPhase {
		this.pkg.addStruct(s.name,s)
		this.structs[s.name] = s
	}
	//eat }
	reader.scan()
}

Parser::genAsyncPollMember(s , idx){
	member = new ast.Member()
	member.parent = s
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

Parser::genAsyncParamMember(s , var){
	member = new ast.Member()
	member.parent = s
	tk = ast.I64

	if var.structtype {
		tk = var.type
	}

	if var.structtype && var.structname != "" {
		if var.stack {
			this.check(false,"async param is stack struct")
		}
		member.structname = var.structname
		member.structpkg  = var.structpkg
		member.isstruct   = true
		member.pointer    = true
		member.structref  = null
		if compile.phase == compile.FunctionPhase
			member.structref = package.getStruct(var.structpkg,var.structname)
		tk = ast.U64
	}
    member.line = this.line
    member.column = this.column
    member.file  = this.filepath
    member.isunsigned = ast.type_isunsigned(tk)
    member.type = tk
    member.size = typesize[int(tk)]
    member.align = typesize[int(tk)]
    member.arrsize = 1
    member.arrvar = null
	member.name = var.varname

	s.member[] = member
}


Parser::parseMembers(s ,idx ,isstruct){
	reader<scanner.ScannerStatic> = this.scanner
	utils.debug("Parser::parseMembers ")
	member = new ast.Member()
	member.parent = s
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
		if compile.phase == compile.FunctionPhase{
            memberStruct = package.getStruct(structpkg,structname)
            this.check(memberStruct != null,"struct not exist")
			member.structref = memberStruct
        }

        tk = ast.U64
    }else {
        if(!this.isbase()) this.check(false,"should be base i8-u64 field define")
        reader.scan()
    }
    if(reader.curToken == ast.MUL){
        member.align = 8
        member.pointer = true
        reader.scan()
    }else {
        if compile.phase == compile.FunctionPhase && isstruct {
            memberStruct = member.structref
            if memberStruct.isapi && !member.pointer {
                this.check(false,"api member must be pointer")
            }
        }
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