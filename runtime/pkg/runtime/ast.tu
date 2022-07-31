

enum 
{
    ILLEGAL END
    INT     STRING  FLOAT   CHAR
    I8		I16		I32		I64		U8		U16		U32		U64
    BITAND  BITOR   BITXOR  BITNOT 
    SHL     SHR     LOGAND  LOGOR   LOGNOT
    EQ		NE		GT		GE		LT		LE
    ADD		SUB		MUL		DIV		MOD

    ASSIGN		ADD_ASSIGN	SUB_ASSIGN	MUL_ASSIGN	
	DIV_ASSIGN	MOD_ASSIGN	SHL_ASSIGN	SHR_ASSIGN	BITAND_ASSIGN	BITOR_ASSIGN
    COMMA		LPAREN		RPAREN		LBRACE		RBRACE			LBRACKET	
	RBRACKET	DOT			COLON		SEMICOLON
    VAR			IF			ELSE		BOOL		WHILE			FOR			
	EMPTY		FUNC		RETURN		BREAK		CONTINUE		NEW
    EXTERN		USE		    CO			CLASS		DELREF		
	EXTRA		MEM			MATCH		ENUM		BUILTIN         GOTO        LEN
}

enum 
{
	Null
	Int
	Float
	String
	Bool
	Char
	Array 
	Map
	Object
}
func token_string(tk<i32>){
	match tk  
	{
        ILLEGAL:    return "invalid"
        VAR:   return "ident"
        END:     return "eof"
        INT:    return "int"
        STRING:    return "string"
        FLOAT: return "double"
        CHAR:  return "char"
        BITAND:	return "&"
        BITOR:	return "|"
        BITXOR:	return "^"
        BITNOT:	return "~"
        SHL:	return "<<"
        SHR:	return ">>"

        LOGAND:	return "&&"
        LOGOR:	return "||"
        LOGNOT:	return "!"
        EQ:	return "=="
        NE:	return "!="
        GT:	return ">"
        GE:	return ">="
        LT:	return "<"
        LE:	return "<="

        //+ - * / %
        ADD:	return "+"
        SUB:	return "-"
        MUL:	return "*"
        DIV:	return "/"
        MOD:	return "%"

        ASSIGN:	return "="
        ADD_ASSIGN:	return "+="
        SUB_ASSIGN:	return "-="
        MUL_ASSIGN:	return "*="
        DIV_ASSIGN:	return "/="
        MOD_ASSIGN:	return "%="
        COMMA:	return ","
        LPAREN:	return "("
        RPAREN:	return ")"
        LBRACE:	return "{"
        RBRACE:	return "}"
        LBRACKET:	return "["
        RBRACKET:	return "]"
        DOT:	return "."
        COLON:	return ":"
        IF:	return "if"
        ELSE:	return "else"
        BOOL:	return "bool"
        WHILE:	return "while"
        FOR:	return "for"
        EMPTY:	return "null"
        FUNC:	return "func"
        RETURN:	return "return"
        BREAK:	return "break"
        CONTINUE:	return "continue"
        NEW:	return "new"
        EXTERN:	return "extern"
        USE:	return "use"
        CO:	return "co"
        CLASS:	return "class"
        DELREF:	return "(*)var"
        MATCH:  return "match"
        //i8-u64
        I8: return "i8"
        I16: return "i16"
        I32: return "i32"
        I64: return "i64"
        U8: return "u8"
        U16: return "u16"
        U32: return "u32"
        U64: return "u64"
        _ :	return "undefine"
    }
}