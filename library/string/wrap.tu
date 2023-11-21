use runtime
use fmt
use std
use os
func hash64(s<runtime.Value>){
	if s == 0 return int(std.prime64)
	
	if s.type != runtime.String 
		os.die("hash64: invalid string type")
	return int(
		s.data.(Str).hash64()
	)
}
func hash64string(s<runtime.Value>){
	if s == 0 {
		return string.new(fromulonglong(std.prime64))
	}
	
	if s.type != runtime.String 
		os.die("hash64: invalid string type")
	return string.new(
		fromulonglong(
			s.data.(Str).hash64()
		)
	)
}

func new(init<i8*>){
	return runtime.newobject(
		runtime.STRING,
		init,
		std.hash64(init,std.strlen(init))
	)
}
func newstringfromlen(init<i8*>,l<i32>){
	r<i8*> = newlen(init,l)
	if r == null fmt.println("newlen failed")
	return runtime.newobject(
		runtime.STRING,
		r,
		r.(Str).hash64()
	)
}
func sub(v<runtime.Value>,lo){
	str<Str> = v.data
	l<i32> = *lo
	if l > str.len() {
		return ""
	}

	str += l
	return new(str)
}
func split(s<runtime.Value> , se<runtime.Value>) {
	tokens = []
	sp<i8*> = s.data
	sep<i8*> = se.data

	elements<i32> = 0
	start<i64> = 0
	j<i64> = 0
	sep1<Str> = sep
	sp1<Str>  = sp
	seplen<i32> = sep1.len()
	len<i32>    = sp1.len()
    if seplen < 1 || len <= 0 return tokens

    for (j = 0; j < len - seplen + 1 ; j += 1) {
        //search the separator 
		ssp<i8*> = sp + j
		if seplen == 1 && *ssp == *sep {
			tokens[] = newstringfromlen(sp + start,j - start)
            start = j + seplen
            j = j + seplen - 1 // skip the separator
		}else if std.memcmp(sp + j,sep , seplen) == runtime.Null {
			tokens[] = newstringfromlen(sp + start,j - start)
            start = j + seplen
            j = j + seplen - 1 // skip the separator
		}
    }
    // Add the final element. We are sure there is room in the tokens array.
	tokens[] = newstringfromlen(sp + start, len - start)

	return tokens
}
func index_get(v<runtime.Value>,index<runtime.Value>){
	if  v.type != runtime.String {
        fmt.println("warn: string index not string type")
        os.exit(-1)
    }

    if  v == null || v.data == null || index == null {
        fmt.println("warn: string index is null ,probably something wrong\n")
        os.exit(-1)
    }

	str<i8*> = v.data
	l<i32> = index.data
	if l >= str.(Str).len() {
		fmt.println("warn: string index out of bound ")
		return 0
	}

	str += l
	cn<u8> = *str
	return runtime.newobject(runtime.Char,cn)
}
func tostring(num<runtime.Value>){
	str<Str> = null
	match num.type {
		runtime.Char :{
			str = empty()
			str = str.putc(num.data)
			return string.new(str)
		}
		runtime.String : return num
		runtime.Int :{
			return new(
				fromlonglong(num.data)
			)
			//fix itoa
    		buf<i8:21> = null
    		ilen<i32> = 21
    		std.itoa(num.data,&buf,ilen) 
    		return string.new(buf)
		}
		_: os.dief("[tostring] unsupport type:%s",runtime.type_string(str))
	}
}
func tonumber(str<runtime.Value>){
	match str.type {
		runtime.String:{
			base<i8> = 10
			ret<i64> = std.strtol(str.data,runtime.Null,base)
			return int(ret) 
		}
		runtime.Int: return str
		runtime.Char: {
			return int(str.data)
		}
		_: os.dief("[tonumber] unsupport type:%s",runtime.type_string(str))

	}
}