use asmer.elf
use asmer.utils
use std
use string
use fmt

True<i64>  = 1
False<i64> = 0

func r8islow(tk<i32>){
    if (tk >= KW_RAX && tk < KW_R8 ) || tk == KW_RIP return true
    if tk >= KW_XMM0 && tk < KW_XMM8  return true
    return false
}
func r8ishigh(tk<i32>){
    if tk >= KW_R8 && tk <= KW_R15 return true
    if tk >= KW_XMM8 && tk <= KW_XMM15 return true
    return false
}
// 32-bit forms of r8-r15; need REX.B/R but not REX.W
func r4ishigh(tk<i32>){
    if tk >= KW_R8D && tk <= KW_R15D return true
    return false
}
// rm low-3-bits: rsp/r12/esp/r12d must emit SIB.
func rm_needs_sib(tk<i32>){
    if tk == KW_RSP || tk == KW_ESP || tk == KW_R12 || tk == KW_R12D return true
    return false
}
// rbp/r13/ebp/r13d: mod=00 is RIP-relative, not base-only.
func rm_needs_disp0(tk<i32>){
    if tk == KW_RBP || tk == KW_EBP || tk == KW_R13 || tk == KW_R13D return true
    return false
}
func isr8(tk<i32>){
    if(r8ishigh(tk) || r8islow(tk)) return true 
    return false
}
func isr4(tk<i32>){
    if(tk >= KW_EAX && tk <= KW_EDI) return true
    if r4ishigh(tk) return true
    return false
}
fn isr2(tk<i32>){
    if tk == KW_AX return true
    return false
}
fn isfreg(tk<i32>){
    if tk >= KW_XMM0 && tk <= KW_XMM15 return true
    return false
}
fn isfreglow(tk<i32>){
    if tk >= KW_XMM0 && tk < KW_XMM8 return true
    return false
}
fn isfreghi(tk<i32>){
    if tk >= KW_XMM8 && tk <= KW_XMM15 return true
    return false
}
func isr1(tk<i32>){
    if(tk >= KW_AL && tk <= KW_BH) return true
    return false
}
fn isfloatinst(ty<i32> , dword<i32*>) {
    *dword = 0
    match ty {
        KW_MOVSD | KW_ADDSD | KW_SUBSD | KW_MULSD | KW_DIVSD :{
            *dword = 1
            return true
        }
        KW_MOVSS | KW_ADDSS | KW_SUBSS | KW_MULSS | KW_DIVSS :{
            *dword = 0
            return true
        }
    }
    return false
}
func typesize(ty<i32>){
    match ty {
        KW_QUAD:  return 8.(i8)
        KW_LONG:  return 4.(i8)
        KW_VALUE: return 2.(i8)
        KW_ZERO:  return 1.(i8)
        KW_BYTE:  return 1.(i8)
        _ : {
            utils.error("unkown type in typesize:" + tk_to_string(ty))
        }
    }
}
func reglen(tk<i32>){
    if(tk >= KW_AL && tk <= KW_BH){ 
        return 1.(i8)
    }
    else if(tk >= KW_EAX && tk <= KW_EDI){
        return 4.(i8)
    }
    else if tk == KW_AX {
        return 2.(i8)
    }
    else if r4ishigh(tk){
        return 4.(i8)
    }
    else if(tk >= KW_RAX && tk <= KW_R15){
        return 8.(i8)
    }else if tk >= KW_XMM0 && tk <= KW_XMM15 {
        return 8.(i8)
    }else{
        utils.error("reglen unkown tk:" + int(tk))
    }
    return 0
}
func tk_to_string(tk<i32>){
    match tk {
        KW_MOV:    return "mov"
        KW_CMP:    return "cmp"
        KW_CMPL:   return "cmpl"
        KW_SUB:    return "sub"
        KW_ADD:    return "add"
        KW_MUL:    return "mul"
        KW_LEA:    return "lea"
        KW_TEST:   return "test"
        KW_CALL:   return "call"
        KW_INT:    return "int"
        KW_DIV:    return "div"
        KW_NEG:    return "neg"
        KW_INC:    return "inc"
        KW_DEC:    return "dec"
        KW_JMP:    return "jmp"
        KW_JBE:    return "jbe"
        KW_JE:     return "je"
        KW_JG:     return "jg"
        KW_JGE:    return "jge"
        KW_JL:     return "jl"
        KW_JLE:    return "jle"
        KW_JNE:    return "jne"
        KW_JNA:    return "jna"
        KW_PUSH:   return "push"
        KW_POP:    return "pop"
        KW_RET:    return "ret"
        KW_RAX:    return "rax"
        KW_AX:     return "ax"
        KW_RCX:    return "rcx"
        KW_RDX:    return "rdx"
        KW_RBX:    return "rbx"
        KW_RSP:    return "rsp"
        KW_RBP:    return "rbp"
        KW_RSI:    return "rsi"
        KW_RDI:    return "rdi"
        KW_R8:     return "r8"
        KW_R9:     return "r9"
        KW_R10:    return "r10"
        KW_FS:     return "%fs"
        KW_RIP:    return "rip"
        KW_LABEL:  return "label"
        KW_ZERO:   return ".zero"
        KW_QUAD:   return ".quad"
        KW_LONG:   return ".long"
        KW_VALUE:  return ".value"
        KW_BYTE:   return ".byte"
        KW_INCBIN: return ".incbin"
        KW_BALIGN: return ".balign"
        KW_P2ALIGN: return ".p2align"
        TK_NUMBER: return "number"
        _ : {
            return "unknown" + int(tk)
        }
    }
}

func undef_vocab_hint(name) {
    if name == null || name == "" {
        return
    }
    n = name
    if std.len(n) > 0 && n[0] == '%' {
        n = string.sub(n, 1)
    }
    kind = ""
    regs = ["rax","rbx","rcx","rdx","rsi","rdi","rbp","rsp","rip",
            "r8","r9","r10","r11","r12","r13","r14","r15",
            "eax","ebx","ecx","edx","esi","edi","ebp","esp","ax",
            "r8d","r9d","r10d","r11d","r12d","r13d","r14d","r15d",
            "al","bl","cl","dl","ah","bh","ch","dh"]
    insns = ["mov","movb","movw","movl","movq","movabsq",
             "movzbl","movzwl","movzb","movzx","movsbl","movswl","movsxd",
             "cmp","cmpl","cmpq","test","testl","testq",
             "add","addq","sub","and","or","orl","xor","xorl",
             "lea","neg","inc","dec","not","shl","shr","sar",
             "push","pop","jmp","call","ret"]
    for r : regs {
        if n == r {
            kind = "register"
            break
        }
    }
    if kind == "" {
        for r : insns {
            if n == r {
                kind = "mnemonic"
                break
            }
        }
    }
    if kind == "" {
        return
    }
    fmt.printf("[asmer] undefined symbol '%s' looks like a %s; unknown instructions/regs must fail at assemble time. If you meant a register or insn, check the .s.\n", name, kind)
}
