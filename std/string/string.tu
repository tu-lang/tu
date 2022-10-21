use runtime
use runtime.gc

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

String::len() {
    s<u8*> = this
    flags<u8> = s[-1]
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


String::mark(){
    s<u8*> = this
    if !s return runtime.Null
    size<i32> = stringHdrSize(s[-1])
    if size == 0 return runtime.Null
    gc.gc_mark(s - size)
}

String::dup() {
    return newlen(this, this.len())
}

String::free() {
    s<u8*> = this
    if s == null return runtime.Null
    
    gc.gc_free(s - stringHdrSize(s[-1]))
}

String::updatelen() {
    reallen<u64> = std.strlen(this)
    stringsetlen(this, reallen)
}

String::clear() {
    stringsetlen(this, runtime.Zero)
    s<u8*> = this
    *s = 0
}

String::MakeRoomFor(addlen<u64>) {
    s<u8*> = this
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

    len = this.len()
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
        s[-1] = type        
        stringsetlen(s, len)
    }
    stringsetalloc(s, newlen)
    return s
}

String::catlen(t<u64*>, len<u64>) {
    s<u8*> = this
    curlen<u64> = this.len()

    s = this.MakeRoomFor(len)
    if s == null return runtime.Null
    std.memcpy(s+curlen, t, len)
    stringsetlen(s, curlen + len)

    s[curlen + len] = '\0'
    return s
}

String::cat(t<i8*>) {
    return this.catlen(t,std.strlen(t))
}

String::catstring(t<String>) {
    return this.catlen(t,t.len())
}

String::cpylen( t<i8*>, len<u64>) {
    s<u8*> = this
    if stringalloc(s) < len {
        s = this.MakeRoomFor(len - this.len())
        if s == null return runtime.Null
    }
    std.memcpy(s, t, len)
    s[len] = '\0'
    stringsetlen(s, len)
    return s
}

String::cpy(t<i8*>) {
    return this.cpylen(t,std.strlen(t))
}

String::tolower() {
    s<u8*> = this
    len<u64> = this.len()
    j<u64>   = 0

    for (j<u64> = 0 ; j < len ; j += 1) {
        s[j] = std.tolower(*s)
    }
}

String::toupper() {
    s<u8*> = this
    len<u64> = this.len()
    j<u64> = 0

    for (j<u64> = 0; j < len ; j += 1) {
        s[j] = std.toupper(s[j])
    }
}

//@return 0  => eq
//@return 1  => greater than
//@return -1 => lower than
String::cmp(s2<String>) {
    l1<u64> = 0
    l2<u64> = 0
    minlen<u64> = 0
    cmp<i32> = 0

    l1 = this.len()
    l2 = s2.len()

    # minlen = (l1 < l2) ? l1 : l2
    if l1 < l2 minlen = l1
    else minlen = l2

    cmp = std.memcmp(this,s2,minlen)
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

// %s  origin char*
// %S  wrap  string*
// %i  signed int  
// %I  long signed int
// %u  unsigned int
// %U  long unsigned int
// %%  to '%'
// TODO: return new
String::catfmt(fmt<i8*>, args,args1,args2,args3) {
    s<i8*> = this
    initlen<u64> = this.len()
    f<i8*> = fmt
    i<u64> = 0
    db<i32> = 2
    single<i32> = 1
    s = this.MakeRoomFor(initlen + std.strlen(fmt) * db)
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
            this = s
            s = this.MakeRoomFor(single)
        }
        match *f 
        {
            '%': {
                f   += 1
                next = *f
                match next {
                    's' | 'S' :{
                        //init stack
                        curr = *pp
                        if stack < 1  pp += 8	else pp -= 8
                        if stack == 1 {	pp = &args	pp += 40	}		
                        stack -= 1
                        //stack end
                        str = curr
                        sstr<String> = curr
                        if next == 's' 
                            l = std.strlen(str)
                        else 
                            l = sstr.len()
                        if stringavail(s) < l {
                            this = s
                            s = this.MakeRoomFor(l)
                        }
                        std.memcpy(s + i,str,l)
                        stringinclen(s,l)
                        i += l
                    }
                    'i' | 'I' : {
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
                            this = s
                            s = this.MakeRoomFor(l)
                        }
                        std.memcpy(s + i,buf,l)
                        stringinclen(s,l)
                        i += l
                    }
                    'u' | 'U' : {
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
                            this = s
                            s = this.MakeRoomFor(l)
                        }
                        std.memcpy(s + i,buf,l)
                        stringinclen(s,l)
                        i += l
                    }
                    _ : {
                        s[i] = next
                        i += 1
                        stringinclen(s,single)
                    } 
                }
            }
            _ : {
                s[i] = *f
                i += 1
                stringinclen(s,single)
            }
        }
        f += 1
    }
    s[i] = 0
    return s
}
//TODO: return new
//stringputc
String::putc(c<i8>){
    s<i8*> = this
    single<i64> = 1
    if stringavail(s) < single {
        s = this.MakeRoomFor(single)
    }
    this = s
    i<i32> = this.len()
    stringinclen(s,single)
    s[i] = c
    s[i + 1] = 0
    return s
}
