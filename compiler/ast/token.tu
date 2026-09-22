
Null<i32> = 0
Int<i32> = 1
Double<i32> = 2
String<i32> = 3
Bool<i32> = 4
Char<i32> = 5
Array<i32> = 6
Map<i32> = 7
Object<i32> = 8
Func<i32> = 9


TRUE<i32> = 1
FALSE<i32> = 0
OK<i32> = 0
ERROR<i32> = -1


ILLEGAL<i32> = 0
END<i32> = 1
INT<i32> = 2
STRING<i32> = 3
FLOAT<i32> = 4
CHAR<i32> = 5
I8<i32> = 6
U8<i32> = 7
I16<i32> = 8
U16<i32> = 9
I32<i32> = 10
U32<i32> = 11
I64<i32> = 12
U64<i32> = 13
F32<i32> = 14
F64<i32> = 15
BITAND<i32> = 16
BITOR<i32> = 17
BITXOR<i32> = 18
BITNOT<i32> = 19
SHL<i32> = 20
SHR<i32> = 21
LOGAND<i32> = 22
LOGOR<i32> = 23
LOGNOT<i32> = 24
EQ<i32> = 25
NE<i32> = 26
GT<i32> = 27
GE<i32> = 28
LT<i32> = 29
LE<i32> = 30
ADD<i32> = 31
SUB<i32> = 32
MUL<i32> = 33
DIV<i32> = 34
MOD<i32> = 35
ASSIGN<i32> = 36
ADD_ASSIGN<i32> = 37
SUB_ASSIGN<i32> = 38
MUL_ASSIGN<i32> = 39
BITXOR_ASSIGN<i32> = 40
DIV_ASSIGN<i32> = 41
MOD_ASSIGN<i32> = 42
SHL_ASSIGN<i32> = 43
SHR_ASSIGN<i32> = 44
BITAND_ASSIGN<i32> = 45
BITOR_ASSIGN<i32> = 46
COMMA<i32> = 47
LPAREN<i32> = 48
RPAREN<i32> = 49
LBRACE<i32> = 50
RBRACE<i32> = 51
LBRACKET<i32> = 52
RBRACKET<i32> = 53
DOT<i32> = 54
COLON<i32> = 55
SEMICOLON<i32> = 56
VAR<i32> = 57
IF<i32> = 58
ELSE<i32> = 59
BOOL<i32> = 60
WHILE<i32> = 61
LOOP<i32> = 62
FOR<i32> = 63
EMPTY<i32> = 64
FUNC<i32> = 65
RETURN<i32> = 66
BREAK<i32> = 67
CONTINUE<i32> = 68
NEW<i32> = 69
EXTERN<i32> = 70
USE<i32> = 71
CO<i32> = 72
CLASS<i32> = 73
DELREF<i32> = 74
EXTRA<i32> = 75
MEM<i32> = 76
MATCH<i32> = 77
ENUM<i32> = 78
BUILTIN<i32> = 79
GOTO<i32> = 80
CFG<i32> = 81
ASYNC<i32> = 82
AWAIT<i32> = 83
CONST<i32> = 84
API<i32> = 85
IMPL<i32> = 86
AS<i32> = 87
TRY<i32> = 88
CATCH<i32> = 89
FINALLY<i32> = 90
THROW<i32> = 91
DEFER<i32> = 92
EXPORT<i32> = 93
UNSAFE<i32> = 94
ILLEGAL_END<i32> = 95


type_id<i32> = 9

func getTypeId() {
    ret = type_id
    type_id += 1
    return ret
}

func resetTypeId() {
    type_id = 9
}