use runtime
use fmt
use std
use os

// Export facades: dynamic ABI params; bind to typed locals in body (scheme A).

export func hash64(s){
	sv<runtime.Value> = s
	if sv == 0 return int(std.prime64)
	
	if sv.type != runtime.String 
		os.die("hash64: invalid string type")
	return int(std.hash64(sv.data, std.strlen(sv.data)))
}
export func hash64string(s){
	sv<runtime.Value> = s
	if sv == 0 {
		return new(fromulonglong(std.prime64))
	}
	
	if sv.type != runtime.String 
		os.die("hash64: invalid string type")
	return new(
		fromulonglong(
			std.hash64(sv.data, std.strlen(sv.data))
		)
	)
}

// Static cross-package API: C string → dynamic String Value (string.new in callers).
fn new(init<i8*>){
	return runtime.newobject(
		runtime.STRING,
		init,
		std.hash64(init,std.strlen(init))
	)
}
// Dyn facade when the argument is already a dynamic Value (not a bare i8*).
export func new_value(init){
	sv<runtime.Value> = init
	if sv == null {
		return new(null)
	}
	if sv.type != runtime.String {
		os.die("string.new_value: invalid string type")
	}
	return new(sv.data)
}
// Wrap a counted byte buffer as a dynamic String Value (static callers only).
fn newstringfromlen(init<i8*>, l<i32>){
	r<i8*> = newlen(init,l)
	if r == null fmt.println("newlen failed")
	return runtime.newobject(
		runtime.STRING,
		r,
		std.hash64(r, l)
	)
}
export func sub(v, lo){
	sv<runtime.Value> = v
	lov<runtime.Value> = lo
	str<i8*> = sv.data
	l<i32> = lov.data
	if l > std.strlen(str) {
		return ""
	}

	str += l
	return new(str)
}
export func split(s, se) {
	sv<runtime.Value> = s
	sev<runtime.Value> = se
	tokens = []
	sp<i8*> = sv.data
	sep<i8*> = sev.data

	elements<i32> = 0
	start<i64> = 0
	j<i64> = 0
	seplen<i32> = std.strlen(sep)
	len<i32>    = std.strlen(sp)
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
export func index_get(v, index){
	sv<runtime.Value> = v
	idx<runtime.Value> = index
	if  sv.type != runtime.String {
        fmt.println("warn: string index not string type")
        os.exit(-1)
    }

    if  sv == null || sv.data == null || idx == null {
        fmt.println("warn: string index is null ,probably something wrong\n")
        os.exit(-1)
    }

	str<i8*> = sv.data
	l<i32> = idx.data
	if l >= std.strlen(str) {
		fmt.println("warn: string index out of bound ")
		return 0
	}

	str += l
	cn<u8> = *str
	return runtime.newobject(runtime.Char,cn)
}
export func tostring(num){
	nv<runtime.Value> = num
	match nv.type {
		runtime.Char :{
			buf<i8:2> = null
			buf[0] = nv.data.(u8)
			buf[1] = 0
			return new(&buf)
		}
		runtime.String : return nv
		runtime.Int :{
    		buf<i8:21> = null
    		std.itoa(nv.data,&buf,10.(i8)) 
    		return new(&buf)
		}
		runtime.Float: {
			fnum<runtime.FloatValue> = nv
			s<string.String> = f64tostring(fnum.data,5.(i8))
			return s.dyn()
		}
		_: os.dief("[tostring] unsupport type:%s",runtime.type_string(nv))
	}
}
export func tonumber(str){
	sv<runtime.Value> = str
	match sv.type {
		runtime.String:{
			base<i8> = 10
			ret<i64> = std.strtol(sv.data,runtime.Null,base)
			return int(ret) 
		}
		runtime.Int:  return sv
		runtime.Char: return int(sv.data)
		runtime.Float: {
			vf<runtime.FloatValue> = sv
			v<i64> = vf.data
			return int(v)
		}
		_: os.dief("[tonumber] unsupport type:%s",runtime.type_string(sv))

	}
}
export func tofloat(str){
	sv<runtime.Value> = str
	match sv.type {
		runtime.String:{
        	f<f64> = strtof64(sv.data)
			return runtime.newfobject(f)
		}
		runtime.Int:  {
			f<f64> = sv.data
			return runtime.newfobject(f)
		}
		runtime.Char: {
			f<f64> = sv.data
			return runtime.newobject(f)
		}
		runtime.Float: return sv
		_: os.dief("[tofloat] unsupport type:%s",runtime.type_string(sv))

	}
}
