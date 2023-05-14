use std
use os
use fmt
use compiler.compile
use runtime

class Ast {
    line = line
    column = column
    func init(line,column) {}

    func toString() { return "Ast()" }
}
func parse_err(args...){
    os.die(fmt.sprintf(args))
}
func isbase(ty){
    match ty {
        I8 | U8 | I16 | U16 | I32 | U32 | I64 | U64 : {
            return true
        }
    }
    return false
}
func typesizestring(ty){
    match ty {
        I8  | U8  :  return "byte"
        I16 | U16 :  return "value"
        I32 | U32 :  return "long"
        I64 | U64 :  return "quad"
        _ :          return "byte"
    }    
}

Ast::record(){
    cfunc = compile.currentFunc
    compile.writeln("# line:%d column:%d file:%s",this.line,this.column,cfunc.parser.filepath)
    if compile.debug
        compile.writeln("    .loc %d %d",compile.currentParser.fileno,this.line)
    else
        compile.writeln("# line:%d column:%d file:%s",this.line,this.column,cfunc.parser.filepath)
}
Ast::panic(err){
    cfunc = compile.currentFunc
    parse_err(
        "asmgen error: %s line:%d column:%d file:%s\n",
        err,this.line,this.column,cfunc.parser.filepath
    )
}
Ast::check( check<runtime.Value> , err<i8*>)
{
    //static
    if check == 1 return  null
    if check == 0 goto astcheck_panic 
    //dyn
    c = check
    if c return null
astcheck_panic:

    if err != null {
        fmt.printf("AsmError:%s \n" + 
                "line:%d column:%d file:%s\n\n" +
                "expression:\n%s\n",err,this.line,this.column,GP().filepath,this.toString()
        )
    }else{
        fmt.printf("AsmError:\n" +
                "line:%d column:%d file:%s\n\n" +
                "expression:\n%s\n",this.line,this.column,GP().parser.filepath,this.toString()
        )
    }
    os.die("check failed")
}
func getTokenString(tk) {
    match tk {
        ILLEGAL:    return "invalid"
        VAR:   return "var"
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
        BUILTIN: return "builtin"
        
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

func type_isunsigned(ty<i64>){
    match ty {
        U8 | U16 | U32 | U64 : return true
        _ : return false
    }
}