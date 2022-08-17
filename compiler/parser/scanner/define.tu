
use ast

keywords = {
	"i8"    : ast.I8,      "i16"   : ast.I16,    "i32" 	   : ast.I32,            "i64" : ast.I64,
	"u8"    : ast.U8,      "u16"   : ast.U16,    "u32" 	   : ast.U32,            "u64" : ast.U64,
	"if" 	: ast.IF,     "else"   : ast.ELSE,   "else"    : ast.ELSE,
	"while" : ast.WHILE,   "for"   : ast.FOR,    "false"   : aset.BOOL,
	"true"  : ast.BOOL,    "null"  : ast.EMPTY,  "func"    : ast.FUNC,
	"return": ast.RETURN,  "break" : ast.BREAK,  "continue": ast.CONTINUE,
	"use"   : ast.ast.USE, "extern": ast.EXTERN, "class"   : ast.CLASS,
	"new"   : ast.NEW,     "co"    : ast.CO,     "mem" 	   : ast.MEM, 
	"match" : ast.MATCH ,  "enum"  : ast.ENUM,   "goto"    : ast.GOTO,
	"int"   : ast.BUILTIN, "sizeof": ast.BUILTIN,
}