
keywords

func init(){
	keywords = {
	 	"if" 	: IF,     "else"   : ELSE,   "else"    : ELSE,
		"while" : WHILE,   "for"   : FOR,    "false"   : BOOL,
		"true"  : BOOL,    "null"  : EMPTY,  "func"    : ast.FUNC,
		"return": RETURN,  "break" : BREAK,  "continue": CONTINUE,
		"use"   : ast.USE,     "extern": ast.EXTERN, "class"   : ast.CLASS,
		"new"   : NEW,     "co"    : CO,     "mem" 	   : MEM, 
		"match" : MATCH ,  "enum"  : ENUM,   "goto"    : GOTO,
		"i8"    : ast.I8,      "i16"   : ast.I16,    "i32" 	   : ast.I32,            "i64" : ast.I64,
		"u8"    : ast.U8,      "u16"   : ast.U16,    "u32" 	   : ast.U32,            "u64" : ast.U64,
		"int"   : BUILTIN, "sizeof": BUILTIN,
	}
}