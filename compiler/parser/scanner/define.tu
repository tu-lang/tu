
use compiler.ast

EOF = -1
keywords = {
	"i8"    : ast.I8,      "i16"   : ast.I16,    "i32" 	   : ast.I32,       "i64" : ast.I64,
	"u8"    : ast.U8,      "u16"   : ast.U16,    "u32" 	   : ast.U32,       "u64" : ast.U64,
	"f32"	: ast.F32,	   "f64"   : ast.F64,
	"if" 	: ast.IF,     "else"   : ast.ELSE,
	"while" : ast.WHILE,   "loop"  : ast.LOOP,	   "for"   : ast.FOR,    	"false"   : ast.BOOL,
	"true"  : ast.BOOL,    "null"  : ast.EMPTY,  "func"    : ast.FUNC, 		"fn"  : ast.FUNC,
	"return": ast.RETURN,  "break" : ast.BREAK,  "continue": ast.CONTINUE,
	"use"   : ast.USE, 	   "extern": ast.EXTERN, "class"   : ast.CLASS,
	"new"   : ast.NEW,     "co"    : ast.CO,     "mem" 	   : ast.MEM, 
	"match" : ast.MATCH ,  "enum"  : ast.ENUM,   "goto"    : ast.GOTO,		"cfg"  : ast.CFG,
}
builtins = {
    "int" : true , "sizeof" : true , "type" : true, "float" : true,
	"inter_get_bp" : true,
}
specs = {
	"\\n"  : 10.(i8),
	"\\\\" : 92.(i8),
	"\\t"  : 9.(i8),
	"\\\'" : 39.(i8),
	"\\\"" : 34.(i8),
	"\\b"  : 8.(i8),
	"\\r"  : 13.(i8),
	"\\f"  : 12.(i8),
	"\\0"  : 0.(i8),
	"\\r"  : 13.(i),
	"\\v"  : 11.(i8)
}