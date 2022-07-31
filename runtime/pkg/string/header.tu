use runtime.gc
use runtime
use std
use fmt


LSTRING_MAX_PREALLOC<i32> =  1048576 # 1024 * 1024
LSTRING_LLSTR_SIZE<i32>   = 21


mem Stringhdr5:pack {
	u8 flags    // 3 lsb of type, and 5 msb of string length 
}
mem Stringhdr8:pack {
    u8 len     //used
    u8 alloc   //excluding the header and null terminator 
    u8 flags   //3 lsb of type, 5 unused bits 
}
mem Stringhdr16:pack {
    u16 len   
    u16 alloc
    u8  flags
}
mem Stringhdr32:pack {
    u32 len
    u32 alloc
    u8  flags
}
mem Stringhdr64:pack {
    u64 len
    u64 alloc
    u8  flags
}

LSTRING_TYPE_5<i32>  = 0
LSTRING_TYPE_8<i32>  = 1
LSTRING_TYPE_16<i32> = 2
LSTRING_TYPE_32<i32> = 3
LSTRING_TYPE_64<i32> = 4
LSTRING_TYPE_MASK<i32> =  7
LSTRING_TYPE_BITS<i32> =  3

func LSTRING_HDR(type<i32>,s<u8*>){
    l<i32> = 0
    match type {
        LSTRING_TYPE_5 : l = sizeof(Stringhdr5)
        LSTRING_TYPE_8 : l = sizeof(Stringhdr8)
        LSTRING_TYPE_16: l = sizeof(Stringhdr16)
        LSTRING_TYPE_32: l = sizeof(Stringhdr32)
        LSTRING_TYPE_64: l = sizeof(Stringhdr64)
        _ : fmt.vfprintf(std.STDOUT,*"string: unknown type\n")
    }
    return s - l
} 
func LSTRING_TYPE_5_LEN(f<u8>){
    return f >> LSTRING_TYPE_BITS
}

func stringavail(s<u8*>) {
    hdr<u8*> = s - 1
    flags<u8> = *hdr # s[-1]
    match flags & LSTRING_TYPE_MASK {

        LSTRING_TYPE_5: return runtime.Null
        LSTRING_TYPE_8: {
            sh8<Stringhdr8> = LSTRING_HDR(LSTRING_TYPE_8,s)
            return sh8.alloc - sh8.len
        }
        LSTRING_TYPE_16: {
            sh16<Stringhdr16> = LSTRING_HDR(LSTRING_TYPE_16,s)
            return sh16.alloc - sh16.len
        }
        LSTRING_TYPE_32: {
            sh32<Stringhdr32> = LSTRING_HDR(LSTRING_TYPE_32,s)
            return sh32.alloc - sh32.len
        }
        LSTRING_TYPE_64: {
            sh64<Stringhdr64> = LSTRING_HDR(LSTRING_TYPE_64,s)
            return sh64.alloc - sh64.len
        }
    }
    return runtime.Null
}

func stringsetlen(s<u8*>, newlen<u64>) {
    hdr<u8*> = s - 1
    flags<u8> = *hdr # s[-1]
    
    match flags & LSTRING_TYPE_MASK {
        LSTRING_TYPE_5:{
            nl<u64> = newlen << LSTRING_TYPE_BITS
            *hdr = LSTRING_TYPE_5 | nl
        }
        LSTRING_TYPE_8:{
            sh8<Stringhdr8> = LSTRING_HDR(LSTRING_TYPE_8,s)
            sh8.len = newlen
        }
        LSTRING_TYPE_16:{
            sh16<Stringhdr16> = LSTRING_HDR(LSTRING_TYPE_16,s)
            sh16.len = newlen
        }
        LSTRING_TYPE_32:{
            sh32<Stringhdr32> = LSTRING_HDR(LSTRING_TYPE_32,s)
            sh32.len = newlen
        }
        LSTRING_TYPE_64:{
            sh64<Stringhdr64> = LSTRING_HDR(LSTRING_TYPE_64,s)
            sh64.len = newlen
        }
        _ : fmt.vfprintf(std.STDOUT,*"string: unknow type")
    }
}

func stringinclen(s<u8*>, inc<u64>) {
    hdr<u8*> = s - 1
    flags<u8> = *hdr # s[-1]
    match flags & LSTRING_TYPE_MASK {
        LSTRING_TYPE_5:{
            newlen<u8> = LSTRING_TYPE_5_LEN(flags)
            newlen += inc
            newlen <<= LSTRING_TYPE_BITS
            *hdr = LSTRING_TYPE_5 | newlen
        }
        LSTRING_TYPE_8:{
            sh8<Stringhdr8> = LSTRING_HDR(LSTRING_TYPE_8,s)
            sh8.len += inc
        }
        LSTRING_TYPE_16:{
            sh16<Stringhdr16> = LSTRING_HDR(LSTRING_TYPE_16,s)
            sh16.len += inc
        }
        LSTRING_TYPE_32:{
            sh32<Stringhdr32> = LSTRING_HDR(LSTRING_TYPE_32,s)
            sh32.len += inc
        }
        LSTRING_TYPE_64:{
            sh64<Stringhdr64> = LSTRING_HDR(LSTRING_TYPE_64,s)
            sh64.len += inc
        }
        _ : fmt.vfprintf(std.STDOUT,*"string: unknow type")
    }
}

//stringalloc() == stringavail() + stringlen()
func stringalloc(s<u8*>) {
    hdr<u8*> = s - 1
    flags<u8> = *hdr # s[-1]
    
    match flags & LSTRING_TYPE_MASK {
        LSTRING_TYPE_5: return LSTRING_TYPE_5_LEN(flags)
        LSTRING_TYPE_8:{
            sh8<Stringhdr8> = LSTRING_HDR(LSTRING_TYPE_8,s)
            return sh8.alloc
        }
        LSTRING_TYPE_16:{
            sh16<Stringhdr16> = LSTRING_HDR(LSTRING_TYPE_16,s)
            return sh16.alloc
        }
        LSTRING_TYPE_32:{
            sh32<Stringhdr32> = LSTRING_HDR(LSTRING_TYPE_32,s)
            return sh32.alloc
        }
        LSTRING_TYPE_64:{
            sh64<Stringhdr64> = LSTRING_HDR(LSTRING_TYPE_64,s)
            return sh64.alloc
        }
        _ : fmt.vfprintf(std.STDOUT,*"string: unknow type")
    }
}

func stringsetalloc(s<u8*>, newlen<u64>) {
    hdr<u8*> = s - 1
    flags<u8> = *hdr # s[-1]
    
    match flags & LSTRING_TYPE_MASK {
        LSTRING_TYPE_5: return runtime.Null
        LSTRING_TYPE_8:{
            sh8<Stringhdr8> = LSTRING_HDR(LSTRING_TYPE_8,s)
            sh8.alloc = newlen
        }
        LSTRING_TYPE_16:{
            sh16<Stringhdr16> = LSTRING_HDR(LSTRING_TYPE_16,s)
            sh16.alloc = newlen
        }
        LSTRING_TYPE_32:{
            sh32<Stringhdr32> = LSTRING_HDR(LSTRING_TYPE_32,s)
            sh32.alloc = newlen
        }
        LSTRING_TYPE_64:{
            sh64<Stringhdr64> = LSTRING_HDR(LSTRING_TYPE_64,s)
            sh64.alloc = newlen
        }
        _ : {
            fmt.vfprintf(std.STDOUT,*"string: unknow type\n")
        }
    }
}
