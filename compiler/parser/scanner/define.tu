
use compiler.ast

EOF = -1
keywords = {
	"i8"    : ast.I8,      "i16"   : ast.I16,    "i32" 	   : ast.I32,            "i64" : ast.I64,
	"u8"    : ast.U8,      "u16"   : ast.U16,    "u32" 	   : ast.U32,            "u64" : ast.U64,
	"if" 	: ast.IF,     "else"   : ast.ELSE,
	"while" : ast.WHILE,   "loop"  : ast.LOOP,	   "for"   : ast.FOR,    "false"   : ast.BOOL,
	"true"  : ast.BOOL,    "null"  : ast.EMPTY,  "func"    : ast.FUNC,
	"return": ast.RETURN,  "break" : ast.BREAK,  "continue": ast.CONTINUE,
	"use"   : ast.USE, 	   "extern": ast.EXTERN, "class"   : ast.CLASS,
	"new"   : ast.NEW,     "co"    : ast.CO,     "mem" 	   : ast.MEM, 
	"match" : ast.MATCH ,  "enum"  : ast.ENUM,   "goto"    : ast.GOTO,
	"int"   : ast.BUILTIN, "sizeof": ast.BUILTIN,
}
builtins = {
    "int" : true , "sizeof" : true , "type" : true,
}
specs = {
	"\\n"  : 10,
	"\\\\" : 92,
	"\\t"  : 9,
	"\\\'" : 39,
	"\\\"" : 34,
	"\\b"  : 8,
	"\\r"  : 13,
	"\\f"  : 12,
	"\\0"  : 0,
	"\\r"  : 13,
	"\\v"  : 11
}