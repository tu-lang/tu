use std
use string

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
            else                      tmstr = string.stringcat(tmstr,rhs.data)
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

    //说明其中有一个数字 那就多次相加
    count<i64> = null
    match lhs.type {
        Int : count = lhs.data 
        _   : count = rhs.data
    }

    srcv<Value> = null
    if lhs.type == String srcv = lhs
    else srcv = rhs

    // 在字符串运算中都是从新生成一份内存来进行存储结果
    tmstr<i8*> = string.stringdup(srcv.data)
    //例如: a = "abc" * 1  需要去除乘以1
    count -= 1
    for (i<i64> = 0 ; i < count ; i += 1) {
        tmstr = string.stringcat(tmstr,srcv.data)
    }
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
