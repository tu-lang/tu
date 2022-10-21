use std
use string
use os

func value_string_plus(lhs<Value>,rhs<Value>)
{
    tmstr<string.String> = string.empty()
    match lhs.type 
	{
		Int   : tmstr = tmstr.catfmt(*"%I%S",lhs.data,rhs.data)
		Bool  : tmstr = tmstr.catfmt(*"%I%S",lhs.data,rhs.data)
        Float : tmstr = tmstr.catfmt(*"%I%S",lhs.data,rhs.data)
        String: {
            _tdup<string.String> = lhs.data
            tmstr = _tdup.dup()
            if rhs.type == Int        tmstr = tmstr.catfmt(*"%I",rhs.data)
            else if rhs.type == Array tmstr = tmstr.cat(arr_tostring(rhs))
            else if rhs.type == Char  tmstr = tmstr.putc(rhs.data)
            else                      tmstr = tmstr.cat(rhs.data)
        }
        Char: {
            match rhs.type {
                Char: {
                    tmstr = tmstr.putc(lhs.data)
                    tmstr = tmstr.putc(rhs.data)
                }
                String: {
                    tmstr = tmstr.putc(lhs.data)
                    tmstr = tmstr.cat(rhs.data)
                }
                _ : return lhs.data + rhs.data
            }
        }
    }
    return tmstr
}

func value_string_minus(lhs<Value>,rhs<Value>)
{
    //字符串的所有相加减直接返回原字符串
    match lhs.type {
        String : return lhs.data
        _      : return rhs.data
    }
}

func value_string_mul(lhs<Value>,rhs<Value>)
{
    rstr<string.String> = rhs.data
    lstr<string.String> = lhs.data
    //如果两个都是字母则返回相加的那部分
    if lhs.type == String && rhs.type == String {
        tmstr<string.String> = rstr.dup()
        tmstr = tmstr.cat(rhs.data)
        return tmstr
    }
    //has number
    if (lhs.type == Int && rhs.type == String) || 
       (lhs.type == String && rhs.type == Int) {
        count<i64> = lhs.data
        if rhs.type == Int count = rhs.data
        srcv<Value> = lhs
        if rhs.type == String srcv = rhs
        // 在字符串运算中都是从新生成一份内存来进行存储结果
        _tmp<string.String> = srcv.data
        tmstr<string.String> = _tmp.dup()
        count -= 1
        for (i<i64> = 0 ; i < count ; i += 1) {
            tmstr = tmstr.cat(srcv.data)
        }
        return tmstr
    }
    //has char
    match lhs.type {
        Char : {
            tmstr = string.empty()
            tmstr = tmstr.putc(lhs.data)
            tmstr = tmstr.cat(rhs.data)
            return tmstr
        }
        String:{
            match rhs.type {
                Char :{
                    tmstr<string.String> = lstr.dup()
                    tmstr = tmstr.putc(rhs.data)
                    return tmstr
                }
                _: os.dief("[string *] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
            }
        }
        _: os.dief("[string *] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
    }
}
//char int
func value_char2int_mul(lhs<Value>,rhs<Value>){
    tmstr<string.String> = string.empty()
    for (i<i64> = 0 ; i < rhs.data ; i += 1) {
        tmstr = tmstr.putc(lhs.data)
    }
    return tmstr
}
//char char
func value_char2char_mul(lhs<Value>,rhs<Value>){
    tmstr<string.String> = string.empty()

    tmstr = tmstr.putc(lhs.data)
    tmstr = tmstr.putc(rhs.data)
    return tmstr
}

func value_string_div(lhs<Value>,rhs<Value>){
    return Null
}
func value_string_bitand(lhs<Value>,rhs<Value>){
    return Null
}
func value_string_bitor(lhs<Value>,rhs<Value>){
    return Null
}
func value_string_shift_left(lhs<Value>,rhs<Value>){
    return Null
}
func value_string_shift_right(lhs<Value>,rhs<Value>){
    return Null
}
func value_string_equal(lhs<Value>,rhs<Value>,equal<i32>){
    //必须为两个string 才能比较
    if lhs.type != String || rhs.type != String {
        // == 就返回false
        // != 就返回true
        if equal return False
        else return True
    }
    //TODO: c函数调用自动判断为mem运算 if _stringcmp(..) == 0 {}
    s<string.String> = lhs.data
    ret<i8> = s.cmp(rhs.data)
    if ret == 0 {
        // == 返回true
        // != 返回false
        if equal return True
        else return False
    }
    if equal return False
    else return True

}
//< <=
func value_string_lowerthan(lhs<Value>,rhs<Value>,equal<i32>){
    //必须为两个string 才能比较
    if lhs.type != String || rhs.type != String {
        return False
    }
    s<string.String> = lhs.data
    eq<i32> = s.cmp(rhs.data) 
    if equal {
        return eq <= 0
    }
    return eq < 0
}
//> >=
func value_string_greaterthan(lhs<Value>,rhs<Value>,equal<i32>){
    //必须为两个string 才能比较
    if lhs.type != String || rhs.type != String {
        return False
    }
    s<string.String> = lhs.data
    eq<i32> = s.cmp(rhs.data) 
    if equal return eq >= 0
    return eq > 0
}
