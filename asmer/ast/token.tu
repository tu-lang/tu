enum {
    INVALID ,   TK_EOF,
    KW_STRING,  KW_QUAD,    KW_ZERO,    KW_LONG,    KW_VALUE,
    KW_BYTE,    KW_GLOBAL,  KW_DATA,    KW_TEXT,    KW_SIZE,    KW_LABEL,
    KW_DEBUG_FILE, KW_DEBUG_LOC,

    TK_NUMBER, // int
    TK_DOUBLE, // double
    TK_STRING, // string
    TK_DOT,    // .
    TK_COLON,  // :
    TK_COMMA,  // ,
    TK_MUL,    // *
    TK_AT,     // @
    TK_IMME,   // $ immediate
    TK_SUB,    // -
    TK_REM,    // %
    TK_LPAREN, // (
    TK_RPAREN, // )
    // need 2 op
    KW_MOV,     KW_MOVB,    KW_MOVW,      KW_MOVL,       KW_MOVQ,
    KW_MOVSXD,  KW_MOVSBL,  KW_MOVZB,     KW_MOVZBL,     KW_MOVZX,  
    KW_MOVZWL,  KW_MOVSWL,  KW_SHL,       KW_SHR,        KW_SAR,
    KW_CMP,     KW_CMPXCHG, KW_XCHG,      KW_SUB,        KW_ADD,
    KW_XADD,    KW_AND,     KW_MUL,       KW_OR,         KW_XOR,
    KW_CVTSI2SD,KW_CVTSI2SS,KW_CVTSI2SDL, KW_CVTTSS2SI, KW_CVTTSS2SIQ, KW_CVTTSD2SI, KW_CVTTSD2SIQ, 
    KW_CVTPS2PD,KW_CVTPD2PS,KW_CVTSS2SD,  KW_CVTSD2SS,   KW_UCOMISD,
    KW_MOVSD,   KW_MOVSS,   KW_ADDSD,     KW_ADDSS,
    KW_SUBSD,   KW_SUBSS,   KW_MULSD,     KW_MULSS,
    KW_DIVSD,   KW_DIVSS,   KW_UNPCKLPS,
    KW_LEA,
    // need 1 op
    KW_CALL,    KW_SETZ,    KW_SETE,    KW_SETL,    KW_SETLE,   KW_SETAE,   KW_SETGE,
    KW_SETBE,   KW_SETA,    KW_SETG,    KW_SETNZ,   KW_SETNE,   KW_SETP,    KW_SETNP,   KW_SETB,    KW_INT,
    KW_DIV,     KW_IDIV,    KW_NEG,     KW_INC,     KW_DEC,
    KW_JMP,     KW_JBE,     KW_JE,      KW_JG,      KW_JL,      KW_JLE,
    KW_JNE,     KW_JNA,     KW_NOT,     KW_PUSH,    KW_POP,

    //need 0 op
    KW_RET,     KW_LOCK,    KW_RDTSCP,  KW_PAUSE,   KW_LEAVE,   KW_SYSCALL,
    KW_CLTD,    KW_CQO,     KW_CDQ,

    KW_AL, KW_CL , KW_DL, KW_BL, 
    KW_AH, KW_CH , KW_DH, KW_BH,

    KW_EAX, KW_ECX , KW_EDX , KW_EBX , 
    KW_ESP, KW_EBP,  KW_ESI,  KW_EDI,

    KW_RAX,  KW_RCX,  KW_RDX,   KW_RBX,   KW_RSP,
    KW_RBP,  KW_RSI,  KW_RDI,   KW_R8,    KW_R9,
    KW_R10,  KW_R11,  KW_R12,   KW_R13,   KW_R14,   KW_R15, 
    KW_XMM0, KW_XMM1, KW_XMM2,  KW_XMM3,  KW_XMM4,  KW_XMM5,  KW_XMM6,  KW_XMM7, 
    KW_XMM8, KW_XMM9, KW_XMM10, KW_XMM11, KW_XMM12, KW_XMM13, KW_XMM14, KW_XMM15, 
    KW_FS,KW_RIP,
}

enum {
    TY_INVAL,
    TY_IMMED,
    TY_REG,
    TY_MEM,
}
