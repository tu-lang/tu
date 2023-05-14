
use std
use os
use fmt
use string


 // + operator
 // @param lhs
 // @param rhs
 // @return value
func value_plus(lhs<Value>,rhs<Value>) {
	result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    //有字符串就最终类型是字符串
    if lhs.type == String || rhs.type == String {
        result.type = String
        result.data = value_string_plus(lhs,rhs)
        return result
    }
    //有int类型就进行int类型相加
    if lhs.type == Int || rhs.type == Int {
        result.type = Int
        result.data = value_int_plus(lhs,rhs)
        return result
    }
    if lhs.type == Char || rhs.type == Char {
        result.type = String
        if lhs.type == Int || rhs.type == Int 
            result.type = Int
        if lhs.type == Char{
            result.data = value_string_plus(lhs,rhs)    
            return result
        } 
        if rhs.type == Char {
            result.data = value_string_plus(rhs,lhs)    
            return result
        }
    }
    os.dief("[operator+] unknown type lhs:%s rhs:%s" ,type_string(lhs) ,type_string(rhs))
}
 // - operator
 // @param lhs
 // @param rhs
 // @return
func value_minus(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    //有字符串就最终类型是字符串
    if lhs.type == String || rhs.type == String {
        result.type = String
        result.data = value_string_minus(lhs,rhs)
        return result
    }
    //有int类型就进行int类型相加
    if  lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.type = Int
        result.data = value_int_minus(lhs,rhs)
        return result
    }
    os.dief("[operator-] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}
 //* operator
 // @param lhs
 // @param rhs
 // @return
func value_mul(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    //有字符串就最终类型是字符串
    if lhs.type == String || rhs.type == String {
        result.type = String
        result.data = value_string_mul(lhs,rhs)
        return result
    }
    //有int类型就进行int类型相加
    if (lhs.type == Int && rhs.type == Int ) || lhs.type == Null{
        result.type = Int
        result.data = value_int_mul(lhs,rhs)
        return result
    }
    if (lhs.type == Int && rhs.type == Char) ||
       (lhs.type == Char && rhs.type == Int) {
        result.type = String
        if lhs.type == Int  
            result.data = value_char2int_mul(rhs,lhs)
        else 
            result.data = value_char2int_mul(lhs,rhs)
        return result
    }
    if lhs.type == Char && rhs.type == Char {
        result.type = String
        result.data = value_char2char_mul(lhs,rhs)
        return result
    }
    os.dief("[operator*] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}
 // / operator
 // @param lhs
 // @param rhs
 // @return
func value_div(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    //字符串的触发运算全部返回0
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_div(lhs,rhs)
        return result
    }
    //有int类型就进行int类型相加
    if lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.type = Int
        result.data = value_int_div(lhs,rhs)
        return result
    }
    os.dief("[operator/] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}
 // & operator
 // @param lhs
 // @param rhs
 // @return
func value_bitand(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    //字符串的触发运算全部返回0
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_bitand(lhs,rhs)
        return result
    }
    //有int类型就进行int类型相加
    if  lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.type = Int
        result.data = value_int_bitand(lhs,rhs)
        return result
    }
    os.dief("[operator&] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}
 // | operator
 // @param lhs
 // @param rhs
 // @return
func value_bitor(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    //字符串的触发运算全部返回0
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_bitor(lhs,rhs)
        return result
    }
    //有int类型就进行int类型相加
    if lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.type = Int
        result.data = value_int_bitor(lhs,rhs)
        return result
    }
    os.dief("[operator|] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}
 // @return
 func value_bitxor(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    //字符串的触发运算全部返回0
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_bitxor(lhs,rhs)
        return result
    }
    //有int类型就进行int类型相加
    if lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.type = Int
        result.data = value_int_bitxor(lhs,rhs)
        return result
    }
    os.dief("[operator|] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}

 // << operator
 // @param lhs
 // @param rhs
 // @return
 
func value_shift_left(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    //字符串的触发运算全部返回0
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_shift_left(lhs,rhs)
        return result
    }
    //有int类型就进行int类型相加
    if lhs.type == Int || rhs.type == Int {
        result.type = Int
        result.data = value_int_shift_left(lhs,rhs)
        return result
    }
    if lhs.type == Char && rhs.type == Char {
        result.type = String
        result.data = value_string_plus(lhs,rhs)
        return result
    }
    os.dief("[operator<<] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}

 // >> operator
 // @param lhs
 // @param rhs
 // @return
 
func value_shift_right(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    //字符串的触发运算全部返回0
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_shift_right(lhs,rhs)
        return result
    }
    //有int类型就进行int类型相加
    if lhs.type == Int || rhs.type == Int {
        result.type = Int
        result.data = value_int_shift_right(lhs,rhs)
        return result
    }
    if lhs.type == Char && rhs.type == Char {
        result.type = String
        result.data = value_string_plus(lhs,rhs)
        return result
    }
    os.dief("[operator>>] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}

 // == operator
 // @param lhs
 // @param rhs
 // @return Value*
 
func value_equal(lhs<Value>,rhs<Value>,equal<i32>) {
    result<Value> = new Value
    result.type = Bool
    result.data = 0
    // 如果有string则直接进行string比较
    if lhs.type == String || rhs.type == String {
        result.data = value_string_equal(lhs,rhs,equal)
        return result
    //有int类型就进行int类型相加
    } else if lhs.type == Int || rhs.type == Int || lhs.type == Char {
        result.data = value_int_equal(lhs,rhs,equal)
    //other use int to compare
    }else{
        result.data = value_int_equal(lhs,rhs,equal)
    }
    return result
}

// < operator
// @param lhs
// @param rhs
// @return Value*
func value_lowerthan(lhs<Value>,rhs<Value>,equal<i32>)
{
    result<Value> = new Value
    result.type = Bool
    //默认为true  小于
    result.data = 1
    // 如果有string则直接进行string比较
    if lhs.type == String || rhs.type == String {
        result.data = value_string_lowerthan(lhs,rhs,equal)
        return result
    }
    //有int类型就进行int类型相加
    if lhs.type == Int || rhs.type == Int ||lhs.type == Char || rhs.type == Char {
        result.data = value_int_lowerthan(lhs,rhs,equal)
        return result
    }
    os.dief("[operator>=] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}

 // > operator
 // @param lhs
 // @param rhs
 // @return Value*
func value_greaterthan(lhs<Value>,rhs<Value>,equal<i32>)
{
    result<Value> = new Value
    result.type = Bool
    //默认为true  大于
    result.data = 1
    // 如果有string则直接进行string比较
    if lhs.type == String || rhs.type == String {
        result.data = value_string_greaterthan(lhs,rhs,equal)
        return result
    }
    //有int类型就进行int类型相加
    if lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.data = value_int_greaterthan(lhs,rhs,equal)
    }
    return result
}


// && operator
// @param lhs
// @param rhs
// @return value
func value_logand(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    result.type = Bool
    result.data = False
    if isTrue(lhs) == True && isTrue(rhs) == True {
        result.data = True
    }
    return result
}
func value_logor(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    result.type = Bool
    result.data = False
    //FIXME: || 两边都是函数调用，导致这个会进行动态计算（但是两边是mem类型）
    if isTrue(lhs) == True || isTrue(rhs)  == True {
        result.data = True
    }
    return result
}
func value_lognot(lhs<Value>) {
    result<Value> = new Value
    result.type = Bool
    result.data = !lhs.data
    return result
}
func value_bitnot(lhs<Value>){
    result<Value> = new Value
    result.type = Int
    result.data = ~lhs.data
    return result
}

// tell if itstrue
// @param cond
// @return bool
func isTrue(cond<Value>){
    if cond == False {
        os.die("isTrue: cond is null ,something wrong  probably")
    }
    match cond.type {
        Int:    return cond.data > 0
        Float: return cond.data > 0
        String: {
            str<string.Str> = cond.data
            return str.len() > Null
        }
        Bool:   return cond.data
        Char:   return cond.data != 0
        #FIXME: coluld: return 0 not return;
        Null:   return False
        Object: return True
        _   :   return False
    }
}

//
// @param opt
// @param lhs
// @param rhs
func operator_switch(opt<i32>,lhs<Value>,rhs<Value>){
    if rhs == null {
        if opt != LOGNOT && opt != BITNOT {
            fmt.vfprintf(std.STDOUT,*"[operator] only !,~ at unary expression,not:%d\n",opt)
            os.exit(-1)
        }
    }
    ret<Value> = null
    match opt {
        ASSIGN:         ret =  rhs
        ADD_ASSIGN:     ret =  value_plus(lhs,rhs)
        ADD:            ret =  value_plus(lhs,rhs)
        SUB_ASSIGN:     ret =  value_minus(lhs,rhs)
        SUB:            ret =  value_minus(lhs,rhs)
        MUL_ASSIGN:     ret =  value_mul(lhs,rhs)
        MUL:            ret =  value_mul(lhs,rhs)
        DIV_ASSIGN:     ret =  value_div(lhs,rhs)
        DIV:            ret =  value_div(lhs,rhs)
        BITAND_ASSIGN:  ret =  value_bitand(lhs,rhs)
        BITAND:         ret =  value_bitand(lhs,rhs)
        BITOR_ASSIGN:   ret =  value_bitor(lhs,rhs)
        BITOR:       ret =  value_bitor(lhs,rhs)
        BITXOR_ASSIGN:   ret =  value_bitxor(lhs,rhs)
        BITXOR:       ret =  value_bitxor(lhs,rhs)
        SHL_ASSIGN:  ret =  value_shift_left(lhs,rhs)
        SHL:         ret =  value_shift_left(lhs,rhs)
        SHR_ASSIGN:  ret =  value_shift_right(lhs,rhs)
        SHR:         ret =  value_shift_right(lhs,rhs)
        LT:          ret =  value_lowerthan(lhs,rhs,False)
        LE:          ret =  value_lowerthan(lhs,rhs,True)
        GE:          ret =  value_greaterthan(lhs,rhs,True)
        GT:          ret =  value_greaterthan(lhs,rhs,False)
        EQ:          ret =  value_equal(lhs,rhs,True)
        NE:          ret =  value_equal(lhs,rhs,False)
        LOGAND:      ret =  value_logand(lhs,rhs)
        LOGOR:       ret =  value_logor(lhs,rhs)
        LOGNOT:      ret =  value_lognot(lhs)
        BITNOT:      ret =  value_bitnot(lhs)
        MOD | MOD_ASSIGN: {
            ret =  new Value {
                type : Int,
                data : lhs.data % rhs.data
            }
        }
        _ : {
            fmt.println("[unary-op] unknown opt:" + int(opt))
            ret = rhs
        }
    }
    return ret
}

//
// @param opt
// @param lhs
// @param rhs
// @return
func unary_operator(opt<i32>,lhs<u64*>,rhs<Value>)
{
    //lhs == Value**
    if lhs == null  {
        os.dief("[unary-op] %s lhs arg is null",token_string(opt))
    }
    if rhs == null {
        os.dief("[unary-op] %s rhs arg is null",token_string(opt))
    }
    ret<Value> = operator_switch(opt,*lhs,rhs)
    //*(Value**)lhs = ret
    *lhs = ret
}

// lhs  rhs 都是堆变量
// rhs == null时可能是一元操作符
// @param opt
// @param lhs
// @param rhs
func binary_operator(opt<i32>, lhs<Value>, rhs<Value>)
{
    if lhs == null {
        os.dief(
            "[binary-op] op:%s probably wrong at there!",
            token_string(opt)
        )
    }
    ret<Value> = operator_switch(opt,lhs,rhs)
    if ret.data == 1 && ret.type == String 
        fmt.println("[binaryop] something error") 
    
    return ret
}

func miss_args(pos<i32>,fname<i8*>,isclass<i8>){
    str = string.new(fname)
    if isclass {
        pos -= 1
    }
    if isclass && pos == 0 {
        fmt.printf("[warn] Missing first argument \'this\' for class memthod %s()\n",str)
        return Null
    }
    fmt.printf("[warn] Missing argument %I for %s()\n",int(pos),str)
}
func check_object(obj<Value>){
    if obj == Null return Null
    if obj.type == Null return Null
    return True
}
func miss_objects(filename<i8*>,funcname<i8*>,line<i32>,column<i32>){
    l = int(line)
    c = int(column)
    os.dief(
        "[error] call to undefined method %s in %s on line  %d column %d\n",
        string.new(funcname),
        string.new(filename),
        l,c
    )
}