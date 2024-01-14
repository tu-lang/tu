enum 
{
    ILLEGAL END
    INT     STRING  FLOAT   CHAR
    I8		U8		I16		U16		I32		U32		I64		U64
    BITAND  BITOR   BITXOR  BITNOT 
    SHL     SHR     LOGAND  LOGOR   LOGNOT
    EQ		NE		GT		GE		LT		LE
    ADD		SUB		MUL		DIV		MOD

    ASSIGN		ADD_ASSIGN	SUB_ASSIGN	MUL_ASSIGN	BITXOR_ASSIGN
	DIV_ASSIGN	MOD_ASSIGN	SHL_ASSIGN	SHR_ASSIGN	BITAND_ASSIGN	BITOR_ASSIGN
    COMMA		LPAREN		RPAREN		LBRACE		RBRACE			LBRACKET	
	RBRACKET	DOT			COLON		SEMICOLON
    VAR			IF			ELSE		BOOL		WHILE			LOOP        FOR			
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

PointerSize<i32>    = 8
True<i32>   		= 1
False<i32>  		= 0
Zero<i32>			= 0
Positive1<i32>		= 1
Negative1<i32> 		= -1

//TODO: prohibit modificate
internal_bool_true<Value:> = new Value {
	type : 4,//Bool
	data : 1
}
internal_bool_false<Value:> = new Value {
	type : 4,//Bool
	data : 0
}
internal_null<Value:> = new Value {
	type : 0, //Null
	data : 0
}

mem Value  { 
	i64 type,data 
}
mem StringValue {
	Value base
	u64   hk
}
mem Object { 
	map.Rbtree* members
	map.Rbtree* funcs
	Object* 	father
	i32			typeid
}
fn type(v<Value>, obj<i8>){
	if obj == 1 {
		match v.type {
			Null : return 0
			Int  : return 1
			Float : return 2
			String : return 3
			Bool : return 4
			Char : return 5
			Array : return 6
			Map  : return 7
			Object : {
				o<Object> = v.data
				return int(o.typeid)
			}
			_    : return "type: unknown type:" + int(v.type)				
		}
	}else {
		return int(v)
	}
}

fn type_string(obj<Value>){
	if obj == null return "null object"
	t<i8> = obj.type
	match t {
		Null : return "null"
		Int  : return "int"
		Float : return "float"
		String : return "string"
		Bool : return "bool"
		Char : return "char"
		Array : return "array"
		Map  : return "map"
		Object : return "object"
		_    : return "unknown type:" + int(t)
	}
}
I8_MAX<i8> = 127 	 
I8_MIN<i8> = -128 				 	
U8_MAX<u8> = 255 						
U8_MIN<u8> = 0 

I16_MAX<i16> = 32767 					
I16_MIN<i16> = -32768 				 	
U16_MAX<u16> = 65535 					
U16_MIN<u16> = 0 

I32_MAX<i32> = 2147483647 				
I32_MIN<i32> = -2147483648 		 	
U32_MAX<u32> = 4294967295 				
U32_MIN<u32> = 0 

I64_MAX<i64> = 9223372036854775807 	
I64_MIN<i64> = -9223372036854775808 	
U64_MAX<u64> = 18446744073709551615 	
U64_MIN<u64> = 0

fn token_string(tk<i32>){
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