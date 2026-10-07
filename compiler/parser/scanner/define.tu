
use compiler.ast

// Keyword -> token table; filled by initKeywords because the values are
// ast globals that are only initialized at program start.
keywords = {}
builtins = {
    "int" : true , "sizeof" : true , "type" : true, "float" : true,
	"inter_get_bp" : true,
	"inter_get_sp" : true,
	"embed" : true,
}
// Escape spelling -> byte value for character literals.
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
// Fills keywords; called from the package init before any scan.
func initKeywords(){
    keywords = {
    	"i8"    : ast.I8,      "i16"   : ast.I16,    "i32" 	   : ast.I32,       "i64" : ast.I64,
    	"u8"    : ast.U8,      "u16"   : ast.U16,    "u32" 	   : ast.U32,       "u64" : ast.U64,
    	"f32"	: ast.F32,	   "f64"   : ast.F64,
    	"if" 	: ast.IF,     "else"   : ast.ELSE,
    	"while" : ast.WHILE,   "loop"  : ast.LOOP,	   "for"   : ast.FOR,    	"false"   : ast.BOOL,
    	"true"  : ast.BOOL,    "null"  : ast.EMPTY,  "func"    : ast.FUNC, 		"fn"  : ast.FUNC,
    	"return": ast.RETURN,  "break" : ast.BREAK,  "continue": ast.CONTINUE,
    	"use"   : ast.USE, 	   "extern": ast.EXTERN, "class"   : ast.CLASS,
    	"new"   : ast.NEW,     "co"    : ast.CO,     "mem" 	   : ast.MEM, 		"await": ast.AWAIT, "async": ast.ASYNC,
    	"match" : ast.MATCH ,  "enum"  : ast.ENUM,   "goto"    : ast.GOTO,		"cfg"  : ast.CFG,
    	"const" : ast.CONST,   "api": ast.API,		 "impl"	   : ast.IMPL,
    	"as"    : ast.AS,
    	"try"   : ast.TRY,     "catch": ast.CATCH,   "finally" : ast.FINALLY,
    	"throw" : ast.THROW,   "defer": ast.DEFER,
    	"export": ast.EXPORT,  "unsafe": ast.UNSAFE,
    }
}
