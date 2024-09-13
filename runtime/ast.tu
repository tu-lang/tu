SweepBlockEntries<i64> = 512 
StackInitSpineCap<i64> = 256

CacheLinePadSize<i64>  = 64
Null<i64> = 0
STDOUT<i64> = 1
THREAD_STACK_SIZE<i64> = 32768
THREAD_TLS_SIZE<i64>   = 1024

// clone
SIGCHLD<i64>      		  = 0x11
CLONE_CHILD_CLEARTID<i64> = 0x00200000
CLONE_VM<i64>             = 0x100
CLONE_FS<i64>             = 0x200
CLONE_FILES<i64>          = 0x400
CLONE_SIGHAND<i64>        = 0x800
CLONE_SYSVSEM<i64>        = 0x40000
CLONE_THREAD<i64>         = 0x10000

// mutex
MutexLocked<i32> = 1
MutexWoken<i32>  = 2 
MutexWaiterShift<i32> = 3

semtable<SemTable:251> = null
mutex_unlocked<u32> = 0
mutex_locked<u32>   = 1
mutex_sleeping<u32> = 2

active_spin<i32> = 4
active_spin_cnt<i32> = 30
passive_spin<i32> = 1

// futex
FUTEX_PRIVATE_FLAG<i32> = 128
FUTEX_WAIT_PRIVATE<i32> = 128
FUTEX_WAKE_PRIVATE<i32> = 129
FUTEX_WAIT<i32> = 0
FUTEX_WAKE<i32> = 1

// sys
_EACCES<i64> = 13
_EINVAL<i64> =  22

ERROR<i64>   = -1
OK<i64>   	 = 0
_EAGAIN<i64> = 0xb
_ENOMEM<i64> = 0xc

_PROT_NONE<i64> =  0x0
_PROT_READ<i64> = 0x1
_PROT_WRITE<i64> = 0x2
_PROT_EXEC<i64> = 0x4

_MAP_ANON<i64> = 0x20
_MAP_PRIVATE<i64> = 0x2
_MAP_FIXED<i64> = 0x10

_MADV_DONTNEED<i64> = 0x4
_MADV_FREE<i64>     = 0x8
_MADV_HUGEPAGE<i64> = 0xe
_MADV_NOHUGEPAGE<i64> = 0xf

pageSize<i64>   = 8192
persistentChunkSize<i64> =  262144 
ptrSize<i64>	= 8
physPageSize<u64> = 0
HugePageSize<u64> = 2097152
True<i64> = 1

fixAllocChunk<i64> 		= 16384

deBruijn64<i64>			= 0x0218a392cd3d5dbf
deBruijnIdx64<u8:64> = [
	0,  1,  2,  7,  3,  13, 8,  19,
	4,  25, 14, 28, 9,  34, 20, 40,
	5,  17, 26, 38, 15, 46, 29, 48,
	10, 31, 35, 54, 21, 50, 41, 57,
	63, 6,  12, 18, 24, 27, 33, 39,
	16, 37, 45, 47, 30, 53, 49, 56,
	62, 11, 23, 32, 36, 44, 52, 55,
	61, 22, 43, 51, 60, 42, 59, 58,
]

enum 
{
    ILLEGAL END
    INT     STRING  FLOAT   CHAR
    I8		U8		I16		U16		I32		U32		I64		U64    F32    F64
    BITAND  BITOR   BITXOR  BITNOT 
    SHL     SHR     LOGAND  LOGOR   LOGNOT
    EQ		NE		GT		GE		LT		LE
    ADD		SUB		MUL		DIV		MOD

    ASSIGN		ADD_ASSIGN	SUB_ASSIGN	MUL_ASSIGN	BITXOR_ASSIGN
	DIV_ASSIGN	MOD_ASSIGN	SHL_ASSIGN	SHR_ASSIGN	BITAND_ASSIGN	BITOR_ASSIGN
    COMMA		LPAREN		RPAREN		LBRACE		RBRACE			LBRACKET	
	RBRACKET	DOT			COLON		SEMICOLON
    VAR			IF			ELSE		BOOL		WHILE			LOOP        FOR			
	EMPTY		FUNC		RETURN		BREAK		CONTINUE		NEW
    EXTERN		USE		    CO			CLASS		DELREF		
	EXTRA		MEM			MATCH		ENUM		BUILTIN         GOTO        LEN
}

enum 
{
	Null
	Int
	Float
	String
	Bool
	Char
	Array 
	Map
	Object
    Func
}

PointerSize<i32>    = 8
True<i32>   		= 1
False<i32>  		= 0
Zero<i32>			= 0
Positive1<i32>		= 1
Negative1<i32> 		= -1

//TODO: prohibit modificate
internal_bool_true<Value:> = new Value {
	type : 4,//Bool
	data : 1
}
internal_bool_false<Value:> = new Value {
	type : 4,//Bool
	data : 0
}
internal_null<Value:> = new Value {
	type : 0, //Null
	data : 0
}

mem Value  { 
	i64 type,data 
}
mem StringValue {
	Value base
	u64   hk
}
mem ObjectValue {
    Value         base
    VObjHeader*   hdr
	map.Rbtree*   dynm
}
mem FuncObject {
    i64        type
    VObjFunc   hdr  
}

mem FloatValue {
    i64 type
    f64 data
}
mem Object { 
	map.Rbtree* members
	map.Rbtree* funcs
	Object* 	father
	i32			typeid
}

fn type2(v<Value>){
    match v.type {
        Null : return 0
        Int  : return 1
        Float : return 2
        String : return 3
        Bool : return 4
        Char : return 5
        Array : return 6
        Map  : return 7
        Object : {
            o<ObjectValue> = v
            return int(o.hdr)
        }
        Func : return 9
        _    : return "type: unknown type:" + int(v.type)				
    }
}


fn type(v<Value>, obj<i8>){
	if obj == 1 {
		match v.type {
			Null : return 0
			Int  : return 1
			Float : return 2
			String : return 3
			Bool : return 4
			Char : return 5
			Array : return 6
			Map  : return 7
			Object : {
				o<Object> = v.data
				return int(o.typeid)
			}
            Func: return 8
			_    : return "type: unknown type:" + int(v.type)				
		}
	}else {
		return int(v)
	}
}

fn type_string(obj<Value>){
	if obj == null return "null object"
	t<i8> = obj.type
	match t {
		Null : return "null"
		Int  : return "int"
		Float : return "float"
		String : return "string"
		Bool : return "bool"
		Char : return "char"
		Array : return "array"
		Map  : return "map"
		Object : return "object"
        Func : return "func"
		_    : return "unknown type:" + int(t)
	}
}
I8_MAX<i8> = 127 	 
I8_MIN<i8> = -128 				 	
U8_MAX<u8> = 255 						
U8_MIN<u8> = 0 

I16_MAX<i16> = 32767 					
I16_MIN<i16> = -32768 				 	
U16_MAX<u16> = 65535 					
U16_MIN<u16> = 0 

I32_MAX<i32> = 2147483647 				
I32_MIN<i32> = -2147483648 		 	
U32_MAX<u32> = 4294967295 				
U32_MIN<u32> = 0 

I64_MAX<i64> = 9223372036854775807 	
I64_MIN<i64> = -9223372036854775808 	
U64_MAX<u64> = 18446744073709551615 	
U64_MIN<u64> = 0

fn token_string(tk<i32>){
	match tk  
	{
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

        //+ - * / %
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
        //i8-u64
        I8: return "i8"
        I16: return "i16"
        I32: return "i32"
        I64: return "i64"
        U8: return "u8"
        U16: return "u16"
        U32: return "u32"
        U64: return "u64"
        F32: return "f32"
        F64: return "f64"
        _ :	return "undefine"
    }
}
