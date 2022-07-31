use runtime
use runtime.gc

func isspace(c<i32>){
    match c {
        ' ': return runtime.True
        '\t': return runtime.True
        '\v': return runtime.True
        '\n': return runtime.True
        '\f': return runtime.True
        '\r': return runtime.True
        _   : return runtime.False
    }
}
func isdigit(c<i32>)
{
    b<u32> = c
    if (b - '0') < 10 {
        return runtime.True
    }
    return runtime.False
}
func isalpha(c<i32>){
    if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') {
        return runtime.True
    }
    return runtime.False
}
func isupper(c<i32>){
    if c >= 'A' && c <= 'Z' {
        return runtime.True
    }
    return runtime.False
}
func stringlen(s<u8*>) {
    hdr<u8*> = s - 1
    flags<u8>    = *hdr
    match flags & LSTRING_TYPE_MASK {
        LSTRING_TYPE_5: return LSTRING_TYPE_5_LEN(flags)
        LSTRING_TYPE_8:{
            sh8<Stringhdr8> = LSTRING_HDR(LSTRING_TYPE_8,s)
            return sh8.len
        }
        LSTRING_TYPE_16:{
            sh16<Stringhdr16> = LSTRING_HDR(LSTRING_TYPE_16,s)
            return sh16.len
        }
        LSTRING_TYPE_32:{
            sh32<Stringhdr32> = LSTRING_HDR(LSTRING_TYPE_32,s)
            return sh32.len
        }
        LSTRING_TYPE_64:{
            sh64<Stringhdr64> = LSTRING_HDR(LSTRING_TYPE_64,s)
            return sh64.len
        }
    }
    return runtime.Null
}

func stringHdrSize(type<i8>) {
    match type & LSTRING_TYPE_MASK {
        LSTRING_TYPE_5: return sizeof(Stringhdr5)
        LSTRING_TYPE_8: return sizeof(Stringhdr8)
        LSTRING_TYPE_16:return sizeof(Stringhdr16)
        LSTRING_TYPE_32:return sizeof(Stringhdr32)
        LSTRING_TYPE_64:return sizeof(Stringhdr64)
    }
    return runtime.Null
}

func stringReqType(string_size<u64>) {
    flag<u64> = 1
    if string_size < flag << 5     return LSTRING_TYPE_5
    if string_size < flag << 8     return LSTRING_TYPE_8
    if string_size < flag << 16    return LSTRING_TYPE_16
    if string_size < flag << 32    return LSTRING_TYPE_32

    return LSTRING_TYPE_64
}
func stringmark(s<u8*>){
    if !s return runtime.Null
    # previous byte must be flag type
    hdr<u8*> = s - 1
    size<i32> = stringHdrSize(*hdr)
    if size == 0 return runtime.Null
    # hdr + string 
    gc.gc_mark(s - size)
}

// mystring = stringnewlen("abc",3)
// 默认会申请一个默认大小的内存
// mystring = stringnewlen(NULL,0)
func stringnewlen(init<u64*>, initlen<u64>) {
    sh<u64*> = null
    s<u8*> = null

    type<i8> = stringReqType(initlen) 
    //空字符串一般被作为 append 使用，类型现在设置为8
    if type == LSTRING_TYPE_5 && initlen == null 
        type = LSTRING_TYPE_8

    hdrlen<i32> = stringHdrSize(type)

    // flags pointer. 
    fp<u8*> = null

    #init
    sh = gc.gc_malloc(hdrlen + initlen + 1)
    if sh == runtime.Null return runtime.Null
    else if !init         std.memset(sh, runtime.Null, hdrlen + initlen + 1)

    s  = sh + hdrlen
    fp = s - 1
    match type {
        LSTRING_TYPE_5: *fp = type | initlen << LSTRING_TYPE_BITS
        LSTRING_TYPE_8: {
            sh8<Stringhdr8> = LSTRING_HDR(LSTRING_TYPE_8,s)
            sh8.len = initlen
            sh8.alloc = initlen
            *fp = type
        }
        LSTRING_TYPE_16: {
            sh16<Stringhdr16> = LSTRING_HDR(LSTRING_TYPE_16,s)
            sh16.len = initlen
            sh16.alloc = initlen
            *fp = type
        }
        LSTRING_TYPE_32: {
            sh32<Stringhdr32> = LSTRING_HDR(LSTRING_TYPE_32,s)
            sh32.len = initlen
            sh32.alloc = initlen
            *fp = type
        }
        LSTRING_TYPE_64: {
            sh64<Stringhdr64> = LSTRING_HDR(LSTRING_TYPE_64,s)
            sh64.len = initlen
            sh64.alloc = initlen
            *fp = type
        }
    }
    if initlen != runtime.Null && init != runtime.Null
        std.memcpy(s, init, initlen)
    //last pos set '\0' to     
    //s[initlen] = '\0'
    sp<u8*> = s + initlen
    *sp = 0
    return s
}

func stringempty() {
    return stringnewlen(*"",runtime.Zero)
}

func stringnew(init<i8*>) {
    initlen<u64>  = null
    if  init == null  initlen = 0  
    else              initlen = std.strlen(init)

    return stringnewlen(init, initlen)
}

func stringdup(s<u8*>) {
    return stringnewlen(s, stringlen(s))
}

func stringfree(s<u8*>) {
    if s == null return runtime.Null
    
    hdr<u8*> = s - 1
    gc.gc_free(s - stringHdrSize(*hdr))
}

func stringupdatelen(s<u8*>) {
    reallen<u64> = std.strlen(s)
    stringsetlen(s, reallen)
}

func stringclear(s<u8*>) {
    stringsetlen(s, runtime.Zero)
    *s = 0
}

func stringMakeRoomFor(s<u8*>, addlen<u64>) {
    sh<u64*> = null
    newsh<u64*> = null
    avail<u64> = stringavail(s)
    len<u64> = 0
    newlen<u64> = 0

    ht<u8*> = s - 1 
    type<i8> = *ht & LSTRING_TYPE_MASK
    oldtype<i8> = *ht & LSTRING_TYPE_MASK
    hdrlen<i32> = 0

    if avail >= addlen return s

    len = stringlen(s)
    sh = s - stringHdrSize(oldtype)
    newlen =  len + addlen
    if newlen < LSTRING_MAX_PREALLOC
        newlen *= 2
    else
        newlen += LSTRING_MAX_PREALLOC

    type = stringReqType(newlen)

    if type == LSTRING_TYPE_5 type = LSTRING_TYPE_8

    hdrlen = stringHdrSize(type)
    if oldtype == type {
        newsh = gc.gc_realloc(sh, hdrlen + newlen + 1)
        if newsh == null return runtime.Null
        s = newsh + hdrlen
    } else {
        newsh = gc.gc_malloc(hdrlen + newlen+1)
        if newsh == null return runtime.Null
        std.memcpy(newsh + hdrlen, s, len + 1)
        gc.gc_free(sh)
        s = newsh + hdrlen
        ht = s - 1
        #s[-1] = type
        *ht = type
        stringsetlen(s, len)
    }
    stringsetalloc(s, newlen)
    return s
}

func stringcatlen(s<u8*>,t<u64*>, len<u64>) {
    curlen<u64> = stringlen(s)

    s = stringMakeRoomFor(s,len)
    if s == null return runtime.Null
    std.memcpy(s+curlen, t, len)
    stringsetlen(s, curlen + len)

    sp<u8*> = s + curlen + len
    # s[curlen+len] = '\0'
    *sp = 0
    return s
}

func stringcat(s<u8*>, t<i8*>) {
    return stringcatlen(s, t, std.strlen(t))
}

func stringcatstring(s<u8*>, t<u8*>) {
    return stringcatlen(s, t, stringlen(t))
}

func stringcpylen(s<u8*>, t<i8*>, len<u64>) {
    if stringalloc(s) < len {
        s = stringMakeRoomFor(s,len - stringlen(s))
        if s == null return runtime.Null
    }
    std.memcpy(s, t, len)
    sp<u8*> = s + len
    #s[len] = '\0'
    *sp = 0
    stringsetlen(s, len)
    return s
}

func stringcpy(s<u8*>, t<i8*>) {
    return stringcpylen(s, t, std.strlen(t))
}

func stringll2str(s<i8*>, value<i64>) {
    p<i8*> = null
    aux<i8> = null
    v<i64> = null
    l<u64> = null

    if value < 0 
        v = 0 - value 
    else 
        v = value
    p = s
    while v != null {
        # '0' + (v % 10)
        *p = 48 + v % 10
        p += 1
        v /= 10
    }
    if value < 0{
        #*p = '-' 45
        *p = 45
        p += 1
    } 

    l = p - s
    *p = 0

    p -= 1
    while s < p  {
        aux = *s
        *s = *p
        *p = aux
        s += 1
        p -= 1
    }
    return l
}

func stringull2str(s<i8*>, v<u64>) {
    p<i8*> = null
    aux<i8> = null
    l<u64> = null

    p = s
    while v != null {
        # *p++ = '0'+(v%10)
        *p = 48 + v % 10
        p += 1
        v /= 10
    } 

    l = p - s
    *p = 0

    p -= 1
    while s < p {
        aux = *s
        *s = *p
        *p = aux
        s += 1
        p -= 1
    }
    return l
}

func stringfromlonglong(value<i64>) {

    buf<i8*> = new LSTRING_LLSTR_SIZE 
    len<i32> = stringll2str(buf,value)

    return stringnewlen(buf,len)
}


func stringtolower(s<u8*>) {
    len<u64> = stringlen(s)
    j<u64>   = 0

    for (j<u64> = 0 ; j < len ; j += 1) {
        sp<u8*> = s + j
        #s[j] = tolower(s[j])
        *sp = std.tolower(*s)
    }
}

func stringtoupper(s<u8*>) {
    len<u64> = stringlen(s)
    j<u64> = 0

    for (j<u64> = 0; j < len ; j += 1) {
        sp<u8*> = s + j
        # s[j] = toupper(s[j])
        *sp = std.toupper(*sp)
    }
}

func stringcmp(s1<u8*>, s2<u8*>) {
    l1<u64> = 0
    l2<u64> = 0
    minlen<u64> = 0
    cmp<i32> = 0

    l1 = stringlen(s1)
    l2 = stringlen(s2)

    # minlen = (l1 < l2) ? l1 : l2
    if l1 < l2 minlen = l1
    else minlen = l2

    cmp = std.memcmp(s1,s2,minlen)
    if cmp == 0 {
        # return l1>l2? 1: (l1<l2? -1: 0)
        if l1 > l2 return runtime.Positive1
        else {
            if l1 < l2 return runtime.Negative1
            else return runtime.Zero
        }
    }
    return cmp
}



func string_malloc(size<u64>) { 
    return gc.gc_malloc(size) 
}
func string_realloc(ptr<u64*>, size<u64>) { 
    return gc.gc_realloc(ptr,size) 
}
func string_free(ptr<u64*>) {
    gc.gc_free(ptr) 
}

func stringcatfmt(s<i8*>, fmt<i8*>, args,args1,args2,args3) {
    initlen<u64> = stringlen(s)
    f<i8*> = fmt
    i<u64> = 0
    db<i32> = 2
    single<i32> = 1
    s = stringMakeRoomFor(s, initlen + std.strlen(fmt) * db)
    f = fmt    
    i = initlen 
    curr<u64> = 0

 	pp<u64*> = &args
	stack<i32> = 4   
    while *f != null {


        next<i8> = 0
        str<i8*> = 0
        l<u64>   = 0
        num<i64> = 0
        unum<u64> = 0
        if stringavail(s) == runtime.Zero {
            s = stringMakeRoomFor(s,single)
        }

        match *f 
        {
            flag_percent: {
                f   += 1
                next = *f
                match next {
                    flag_s: goto match_flag_S
                    flag_S:{
                        match_flag_S:
                        //init stack
                        curr = *pp
                        if stack < 1  pp += 8	else pp -= 8
                        if stack == 1 {	pp = &args	pp += 40	}		
                        stack -= 1
                        //stack end
                        str = curr
                        if next == flag_s 
                            l = std.strlen(str)
                        else 
                            l = stringlen(str)
                        if stringavail(s) < l {
                            s = stringMakeRoomFor(s,l)
                        }
                        std.memcpy(s + i,str,l)
                        stringinclen(s,l)
                        i += l
                    }
                    flag_i: goto match_flag_I
                    flag_I:{
                        match_flag_I:
                        //init stack
                        curr = *pp
                        if stack < 1  pp += 8	else pp -= 8
                        if stack == 1 {	pp = &args	pp += 40	}		
                        stack -= 1
                        //stack end
                        num = curr

                        buf_o<i8:21> = 0
                        buf<i8*> = &buf_o
                        l = stringll2str(buf,num)
                        if stringavail(s) < l {
                            s = stringMakeRoomFor(s,l)
                        }
                        std.memcpy(s + i,buf,l)
                        stringinclen(s,l)
                        i += l
                    }
                    flag_u: goto match_flag_U
                    flag_U:{
                        match_flag_U:
                        //init stack
                        curr = *pp
                        if stack < 1  pp += 8	else pp -= 8
                        if stack == 1 {	pp = &args	pp += 40	}		
                        stack -= 1
                        //stack end
                        unum = curr

                        buf_o<i8:21> = 0
                        buf<i8*> = &buf_o
                        l = stringull2str(buf,unum)
                        if stringavail(s) < l {
                            s = stringMakeRoomFor(s,l)
                        }
                        std.memcpy(s + i,buf,l)
                        stringinclen(s,l)
                        i += l
                    }
                    _ : {
                        # s[i++] = next
                        tp<i8*> = s + i
                        i += 1
                        *tp = next
                        stringinclen(s,single)
                    } 
                }
            }
            _ : {
                # s[i++] = *f
                tp<i8*> = s + i
                i += 1
                *tp = *f
                stringinclen(s,1)
            }
        }
        f += 1
    }
    # s[i] = '\0'
    tp<i8*> = s + i
    *tp = 0
    return s
}