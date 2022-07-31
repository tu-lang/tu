class Ast {
    func init(line,column) {
        this.line = line
        this.column = column
    }
    func toString() { return "Ast()" }
    line
    column
}
enum VarType
{
   Var_Obj_Member = -1, 
   Var_Extern_Global, Var_Local_Global,Var_Local_Mem_Global, 
   Var_Local, 
   Var_Func,
}

func getTokenString(tk) {
    match tk {
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

Expression::toString() { return "Expr()" }

Statement::toString() { return "Stmt()" }

BoolExpr::toString() {
    return "BoolExpr(" + literal + ")"
}

CharExpr::toString() {
    return "CharExpr(" + literal + ")"
}

NullExpr::toString() { return "NullExpr()" }

IntExpr::toString() {
    return "int(" + literal + ")"
}

DoubleExpr::toString() {
    return "DoubleExpr(" + literal + ")"
}

StringExpr::toString() { 
    return "StringExpr(" + literal + ") line:" + line + " column:" + column 
}

ArrayExpr::toString() {
    str = "ArrayExpr(elements=["
    if (std.lenliteral) != 0) {
        for (e : literal) {
            str += e.toString()
        }
    }
    str += "])"
    return str
}
MapExpr::toString() {
    str = "MapExpr(elements={"
    if (std.len(literal) != 0) {
        for (e : literal) {
            str += e.toString()
        }
    }
    str += "})"
    return str
}
KVExpr::toString() {
    str = "{"
    if (key)   str += key.toString()
    str += ":"
    if (value) str += value.toString()
    str += "}"
    return str
}

VarExpr::toString() { return "VarExpr(" + varname + ")" }
ClosureExpr::toString() { return "ClosureExpr(" + varname + ")" }

AddrExpr::toString(){
    return "AddrExpr(&(" + package + ")." + varname + ")"
}
DelRefExpr::toString(){
    return "DelRefExpr(" + expr.toString() + ")"
}
BuiltinFuncExpr::toString(){
    return "BuiltinFuncExpr:" + funcname +"("+expr.toString() + ")"
}
StructMemberExpr::toString(){
    return "StructMemberExpr(" + varname + "<"+var.package+"."+var.structname+">"+"."+member+")"
}

IndexExpr::toString() {
    str = "IndexExpr(index="
    if index
        str += index.toString()
    str += ")"
    return str
}

ChainExpr::toString() {
    str = "ChainExpr("
    str += "left=" + first.toString()
    for(i : fields){
        str += "." + i.toString()
    }
    str += ",right=" + last.toString()
    str += ")"
    return str
}

BinaryExpr::toString() {
    str = "BinaryExpr("
    if (opt != ILLEGAL) {
        str += "opt="
        match opt {
            BITAND:
                str += "&"
                break
            BITOR:
                str += "|"
                break
            BITNOT:
                str += "!"
                break
            LOGAND:
                str += "&&"
                break
            LOGOR:
                str += "||"
                break
            LOGNOT:
                str += "!"
                break
            ADD:
                str += "+"
                break
            SUB:
                str += "-"
                break
            MUL:
                str += "*"
                break
            DIV:
                str += "/"
                break
            MOD:
                str += "%"
                break
            EQ:
                str += "=="
                break
            NE:
                str += "!="
                break
            GT:
                str += ">"
                break
            GE:
                str += ">="
                break
            LT:
                str += "<"
                break
            LE:
                str += "<="
                break
            ASSIGN:
                str += "="
                break
            _ :
                str += opt
                break
        }
    }
    if (lhs) {
        str += ",lhs="
        if lhs
            str += lhs.toString()
    }
    if (rhs) {
        str += ",rhs="
        if rhs
            str += rhs.toString()
    }
    str += ")"
    return str
}

FunCallExpr::toString() {
    str = "FunCallExpr[func = "
    str += package + "." + funcname
    str += ",args = ("
    for (arg : args) {
        str += arg.toString()
        str += ","
    }
    str += ")]"
    return str
}

AssignExpr::toString() {
    str = "AssignExpr(lhs="
    if lhs
        str += lhs.toString()
    str += ",rhs="
    if rhs
        str += rhs.toString()
    str += ")"
    return str
}
NewClassExpr::toString(){
    str = "NewExpr("
    str += package
    str += ","
    str += name
    str += ")"
    return str
}
NewExpr::toString(){
    str = "NewExpr("
    str += package
    str += ","
    str += name
    str += ")"
    return str
}

MemberExpr::toString(){
    str = "MemberExpr("
    str += varname
    str += "."
    str += membername
    str += ")"
    return str
}
MemberCallExpr::toString() {
    str = "MemberCallExpr(varname="
    str += varname
    str += ",func="
    str += membername
    str += ",args=["
    for (arg : args) {
        str += arg.toString()
        str += ","
    }
    str += "])"
    return str
}


ExpressionStmt::toString() {
    str = "ExpressionStmt(expr="
    str += expr.toString()
    str += ")"
    return str
}

WhileStmt::toString() {
    str = "WhileStmt(cond="
    str += cond.toString()
    str += ",exprs=["
    for (e : block.stmts) {
        str += e.toString()
        str += ","
    }
    str += "])"
    return str
}
IfCaseExpr::toString(){
    str = "cond="
    str += cond.toString()
    str += ",exprs=["
    if block{
        for(e : block.stmts){
            str += e.toString()
            str += ","
        }
    }
    str += "])"
    return str
}
IfStmt::toString() {
    str
    for(cs : cases){
        str += cs.toString()
    }
    str += elseCase.toString()
    return str
}
ForStmt::toString() {
    str = "ForStmt("
    str += " init="  + init.toString()
    str += ",cond="  + cond.toString()
    str += ",after=" + after.toString()
    str += ",exprs=["
    for (e : block.stmts) {
        str += e.toString()
        str += ","
    }
    str += "])"
    return str
}

ReturnStmt::toString() {
    str = "ReturnStmt("
    if (ret) {
        str += "ret="
        str += ret.toString()
    }
    str += ")"
    return str
}

BreakStmt::toString() { return "BreakStmt()" }

ContinueStmt::toString() { return "ContinueStmt()" }
MatchStmt::toString(){
    return "match stmt"
}
MatchCaseExpr::toString(){
    return "match stmt expr"
}

LabelExpr::toString(){
    return "label expr: " + label
}
GotoStmt::toString(){
    return "goto stmt: " + label
}