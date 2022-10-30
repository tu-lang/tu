use ast

token = [ 
	//FIXME: int(ast.INT),   int(ast.INT),  int(ast.STRING) ,int(ast.FLOAT), int(ast.CHAR),int(ast.CHAR),
	int(ast.INT),   int(ast.INT),  int(ast.STRING) ,int(ast.INT), int(ast.CHAR),int(ast.CHAR),
	int(ast.BITAND),int(ast.BITOR),int(ast.BITNOT),
	int(ast.SHL),   int(ast.SHR),  int(ast.LOGAND), int(ast.LOGOR), int(ast.LOGNOT),
	int(ast.EQ),    int(ast.NE),   int(ast.GT), 	int(ast.GE),    int(ast.LT),    int(ast.LE),
	int(ast.ADD),   int(ast.SUB),  int(ast.MUL), 	int(ast.DIV),   int(ast.MOD),
	int(ast.ASSIGN),        int(ast.ADD_ASSIGN), int(ast.SUB_ASSIGN), int(ast.MUL_ASSIGN), 
	int(ast.DIV_ASSIGN),	int(ast.MOD_ASSIGN), int(ast.SHL_ASSIGN), int(ast.SHR_ASSIGN),
	int(ast.BITAND_ASSIGN), int(ast.BITOR_ASSIGN),
	int(ast.COMMA),    int(ast.LPAREN),   int(ast.RPAREN), int(ast.LBRACE), int(ast.RBRACE),
	int(ast.LBRACKET), int(ast.RBRACKET), int(ast.DOT),    int(ast.COLON),  int(ast.SEMICOLON),
	int(ast.VAR),      int(ast.IF),    int(ast.ELSE),
	int(ast.BOOL),     int(ast.BOOL),
	int(ast.WHILE),    int(ast.FOR),
	int(ast.EMPTY),    int(ast.FUNC),
	int(ast.RETURN),   int(ast.BREAK),
	int(ast.CONTINUE), int(ast.NEW),
	int(ast.EXTERN),   int(ast.USE),   int(ast.CO),
	int(ast.CLASS),    int(ast.DELREF),int(ast.VAR),
	int(ast.EXTRA),
	int(ast.MEM),      int(ast.MATCH), int(ast.ENUM),
	int(ast.I8),       int(ast.I16),   int(ast.I32), int(ast.I64), 
	int(ast.U8),       int(ast.U16),   int(ast.U32), int(ast.U64), 
	int(ast.GOTO),
	int(ast.BUILTIN),  int(ast.LPAREN),
	int(ast.BUILTIN),  int(ast.LPAREN),
	int(ast.BUILTIN),  int(ast.LPAREN), int(ast.END)
]

