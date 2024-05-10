
Null    = 0 
Int     = 1 
Double  = 2 
String  = 3 
Bool    = 4 
Char    = 5 
Array   = 6 
Map     = 7 
Object  = 8 
Func    = 9


TRUE    = 1  
FALSE   = 0  
OK      = 0  
ERROR   = -1 


enum {
    ILLEGAL, END,
    INT,   STRING,  FLOAT, CHAR,
    I8,U8,I16,U16,I32,U32,I64,U64,F32,F64,
    BITAND, BITOR,BITXOR,BITNOT ,
    SHL, SHR,LOGAND, LOGOR,  LOGNOT,
    EQ,NE,GT,GE,LT,LE,
    ADD,   SUB,  MUL, DIV, MOD,
    ASSIGN,ADD_ASSIGN,SUB_ASSIGN,MUL_ASSIGN,BITXOR_ASSIGN,DIV_ASSIGN,MOD_ASSIGN,SHL_ASSIGN,SHR_ASSIGN,BITAND_ASSIGN,BITOR_ASSIGN,
    COMMA,LPAREN,RPAREN,LBRACE,RBRACE,LBRACKET,RBRACKET,DOT,COLON,SEMICOLON,
    VAR,IF,ELSE,BOOL,WHILE,LOOP,FOR,EMPTY,FUNC,RETURN,BREAK,CONTINUE,NEW,
    EXTERN,USE,CO,CLASS,DELREF,EXTRA,MEM,MATCH,ENUM,BUILTIN,GOTO
}

type_id = 9

func getTypeId(){
    ret = type_id
    type_id += 1
    return ret
}