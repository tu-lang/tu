use compiler.ast

// Expected token stream for test/case; a func because ast ids are runtime globals.
func tokens(){
    return [ 
	//FIXME: ast.INT,   ast.INT,  ast.STRING ,ast.FLOAT, ast.CHAR,ast.CHAR,
	ast.INT,   ast.INT,  ast.STRING ,ast.INT, ast.CHAR,ast.CHAR,
	ast.BITAND,ast.BITOR,ast.BITNOT,
	ast.SHL,   ast.SHR,  ast.LOGAND, ast.LOGOR, ast.LOGNOT,
	ast.EQ,    ast.NE,   ast.GT, 	ast.GE,    ast.LT,    ast.LE,
	ast.ADD,   ast.SUB,  ast.MUL, 	ast.DIV,   ast.MOD,
	ast.ASSIGN,        ast.ADD_ASSIGN, ast.SUB_ASSIGN, ast.MUL_ASSIGN, 
	ast.DIV_ASSIGN,	ast.MOD_ASSIGN, ast.SHL_ASSIGN, ast.SHR_ASSIGN,
	ast.BITAND_ASSIGN, ast.BITOR_ASSIGN,
	ast.COMMA,    ast.LPAREN,   ast.RPAREN, ast.LBRACE, ast.RBRACE,
	ast.LBRACKET, ast.RBRACKET, ast.DOT,    ast.COLON,  ast.SEMICOLON,
	ast.VAR,      ast.IF,    ast.ELSE,
	ast.BOOL,     ast.BOOL,
	ast.WHILE,    ast.FOR,
	ast.EMPTY,    ast.FUNC,
	ast.RETURN,   ast.BREAK,
	ast.CONTINUE, ast.NEW,
	ast.EXTERN,   ast.USE,   ast.CO,
	ast.CLASS,    ast.DELREF,ast.VAR,
	ast.EXTRA,
	ast.MEM,      ast.MATCH, ast.ENUM,
	ast.I8,       ast.I16,   ast.I32, ast.I64, 
	ast.U8,       ast.U16,   ast.U32, ast.U64, 
	ast.GOTO,
	ast.BUILTIN,  ast.LPAREN,
	ast.BUILTIN,  ast.LPAREN,
	ast.BUILTIN,  ast.LPAREN,
	ast.LOOP,     ast.FUNC,
	ast.ASYNC,    ast.AWAIT,
	ast.CFG,      ast.CONST,
	ast.API,      ast.IMPL,  ast.AS,
	ast.F32,      ast.F64,
	ast.BUILTIN,  ast.LPAREN,
	ast.TRY,      ast.CATCH, ast.FINALLY, ast.THROW, ast.DEFER,
	ast.EXPORT,   ast.UNSAFE,
	ast.BUILTIN,  ast.LPAREN,
	ast.END
]
}
