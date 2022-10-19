use std
use string
use os

func value_string_plus(lhs<Value>,rhs<Value>)
{
    tmstr<i8*> = string.stringempty()
    match lhs.type 
	{
		Int   : tmstr = string.stringcatfmt(tmstr,*"%I%S",lhs.data,rhs.data)
		Bool  : tmstr = string.stringcatfmt(tmstr,*"%I%S",lhs.data,rhs.data)
        Float : tmstr = string.stringcatfmt(tmstr,*"%I%S",lhs.data,rhs.data)
        String: {
            tmstr = string.stringdup(lhs.data)
            if rhs.type == Int        tmstr = string.stringcatfmt(tmstr,*"%I",rhs.data)
            else if rhs.type == Array tmstr = string.stringcat(tmstr,arr_tostring(rhs))
            else if rhs.type == Char  tmstr = string.stringputc(tmstr,rhs.data)
            else                      tmstr = string.stringcat(tmstr,rhs.data)
        }
        Char: {
            match rhs.type {
                Char: {
                    tmstr = string.stringputc(tmstr,lhs.data)
                    tmstr = string.stringputc(tmstr,rhs.data)
                }
                String: {
                    tmstr = string.stringputc(tmstr,lhs.data)
                    tmstr = string.stringcat(tmstr,rhs.data)
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
    //如果两个都是字母则返回相加的那部分
    if lhs.type == String && rhs.type == String {
        tmstr<i8*> = string.stringdup(lhs.data)
        tmstr = string.stringcat(tmstr,rhs.data)
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
        tmstr<i8*> = string.stringdup(srcv.data)
        count -= 1
        for (i<i64> = 0 ; i < count ; i += 1) {
            tmstr = string.stringcat(tmstr,srcv.data)
        }
        return tmstr
    }
    //has char
    match lhs.type {
        Char : {
            tmstr = string.stringempty()
            tmstr = string.stringputc(tmstr,lhs.data)
            tmstr = string.stringcat(tmstr,rhs.data)
            return tmstr
        }
        String:{
            match rhs.type {
                Char :{
                    tmstr<i8*> = string.stringdup(lhs.data)
                    tmstr = string.stringputc(tmstr,rhs.data)
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
    tmstr<i8*> = string.stringempty()
    for (i<i64> = 0 ; i < rhs.data ; i += 1) {
        tmstr = string.stringputc(tmstr,lhs.data)
    }
    return tmstr
}
//char char
func value_char2char_mul(lhs<Value>,rhs<Value>){
    tmstr<i8*> = string.stringempty()
    tmstr = string.stringputc(tmstr,lhs.data)
    tmstr = string.stringputc(tmstr,rhs.data)
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
    ret<i8> = string.stringcmp(lhs.data,rhs.data)
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
    eq<i32> = string.stringcmp(lhs.data,rhs.data) 
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
    eq<i32> = string.stringcmp(lhs.data,rhs.data) 
    if equal return eq >= 0
    return eq > 0
}
