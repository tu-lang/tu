
use std
use os
use string


 // + operator
 // @param lhs
 // @param rhs
 // @return value
fn value_plus(lhs<Value>,rhs<Value>) {
	result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    if lhs.type == String || rhs.type == String {
        result.type = String
        result.data = value_string_plus(lhs,rhs)
        return result
    }
    if lhs.type == Float || rhs.type == Float {
        fret<FloatValue> = new FloatValue
        fret.type = Float
        fret.data = value_float_plus(lhs,rhs)
        return fret
    }
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
    dief(*"[operator+] unknown type lhs:%s rhs:%s" ,type_string(lhs) ,type_string(rhs))
}
 // - operator
 // @param lhs
 // @param rhs
 // @return
fn value_minus(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    if lhs.type == String || rhs.type == String {
        result.type = String
        result.data = value_string_minus(lhs,rhs)
        return result
    }
    if  lhs.type == Float || rhs.type == Float {
        fret<FloatValue> = new FloatValue
        fret.type = Float
        fret.data = value_float_minus(lhs,rhs)
        return fret
    }
    if  lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.type = Int
        result.data = value_int_minus(lhs,rhs)
        return result
    }
    dief(*"[operator-] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}
 //* operator
 // @param lhs
 // @param rhs
 // @return
fn value_mul(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    if lhs.type == String || rhs.type == String {
        result.type = String
        result.data = value_string_mul(lhs,rhs)
        return result
    }
    if  lhs.type == Float || rhs.type == Float {
        fret<FloatValue> = new FloatValue
        fret.type = Float
        fret.data = value_float_mul(lhs,rhs)
        return fret
    }
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
    dief(*"[operator*] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}
 // / operator
 // @param lhs
 // @param rhs
 // @return
fn value_div(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_div(lhs,rhs)
        return result
    }
    if  lhs.type == Float || rhs.type == Float {
        fret<FloatValue> = new FloatValue
        fret.type = Float
        fret.data = value_float_div(lhs,rhs)
        return fret
    }
    if lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.type = Int
        result.data = value_int_div(lhs,rhs)
        return result
    }
    dief(*"[operator/] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}
 // & operator
 // @param lhs
 // @param rhs
 // @return
fn value_bitand(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_bitand(lhs,rhs)
        return result
    }
    if  lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.type = Int
        result.data = value_int_bitand(lhs,rhs)
        return result
    }
    dief(*"[operator&] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}
 // | operator
 // @param lhs
 // @param rhs
 // @return
fn value_bitor(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_bitor(lhs,rhs)
        return result
    }
    if lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.type = Int
        result.data = value_int_bitor(lhs,rhs)
        return result
    }
    dief(*"[operator|] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}
// @return
fn value_bitxor(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_bitxor(lhs,rhs)
        return result
    }
    if lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.type = Int
        result.data = value_int_bitxor(lhs,rhs)
        return result
    }
    dief(*"[operator|] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}

 // << operator
 // @param lhs
 // @param rhs
 // @return
 
fn value_shift_left(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_shift_left(lhs,rhs)
        return result
    }
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
    dief(*"[operator<<] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}

 // >> operator
 // @param lhs
 // @param rhs
 // @return
 
fn value_shift_right(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    if lhs == null {
        std.memcpy(result,rhs, sizeof(Value))
        return result
    }
    if lhs.type == String || rhs.type == String {
        result.type = Int
        result.data = value_string_shift_right(lhs,rhs)
        return result
    }
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
    dief(*"[operator>>] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}

 // == operator
 // @param lhs
 // @param rhs
 // @return Value*
 
fn value_equal(lhs<Value>,rhs<Value>,equal<i32>) {
    result<Value> = new Value
    result.type = Bool
    result.data = 0
    if lhs.type == Object {
        result.data = lhs == rhs
    }else if lhs.type == String || rhs.type == String {
        result.data = value_string_equal(lhs,rhs,equal)
        return result
    } else if lhs.type == Float || rhs.type == Float {
        result.data = value_float_equal(lhs,rhs,equal)
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
fn value_lowerthan(lhs<Value>,rhs<Value>,equal<i32>)
{
    result<Value> = new Value
    result.type = Bool
    result.data = 1
    if lhs.type == String || rhs.type == String {
        result.data = value_string_lowerthan(lhs,rhs,equal)
        return result
    }
    if lhs.type == Float || rhs.type == Float {
        result.data = value_float_lowerthan(lhs,rhs,equal)
        return result
    }
    if lhs.type == Int || rhs.type == Int ||lhs.type == Char || rhs.type == Char {
        result.data = value_int_lowerthan(lhs,rhs,equal)
        return result
    }
    dief(*"[operator>=] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
}

 // > operator
 // @param lhs
 // @param rhs
 // @return Value*
fn value_greaterthan(lhs<Value>,rhs<Value>,equal<i32>)
{
    result<Value> = new Value
    result.type = Bool
    result.data = 1
    if lhs.type == String || rhs.type == String {
        result.data = value_string_greaterthan(lhs,rhs,equal)
        return result
    }
    if lhs.type == Float || rhs.type == Float {
        result.data = value_float_greaterthan(lhs,rhs,equal)
        return result
    }
    if lhs.type == Int || rhs.type == Int || lhs.type == Char || rhs.type == Char {
        result.data = value_int_greaterthan(lhs,rhs,equal)
    }
    return result
}


// && operator
// @param lhs
// @param rhs
// @return value
fn value_logand(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    result.type = Bool
    result.data = False
    if isTrue(lhs) == True && isTrue(rhs) == True {
        result.data = True
    }
    return result
}
fn value_logor(lhs<Value>,rhs<Value>) {
    result<Value> = new Value
    result.type = Bool
    result.data = False
    //FIXME: ||  dyn in  call() || call()
    if isTrue(lhs) == True || isTrue(rhs)  == True {
        result.data = True
    }
    return result
}
fn value_lognot(lhs<Value>) {
    result<Value> = new Value
    result.type = Bool
    match lhs.type {
        Null | Int | Bool :  {
            result.data = !lhs.data
        }
        Char: {
            if lhs.data == '0'
                 result.data = 1
            else result.data = 0
        }
        Float : {
            fl<FloatValue> = lhs 
            result.data = !fl.data
        }
        String : {
            l<i64> = lhs.data.(string.Str).len()
            result.data = !l
        }
        Array : {
            l<i64> = lhs.data.(std.Array).len()
            result.data = !l
        }
        Object | Func | Map : {
            result.data = 0
        }
        _    : return "[!]: unknown type:" + int(lhs.type)				
    }

    return result
}
fn value_bitnot(lhs<Value>){
    result<Value> = new Value
    result.type = Int
    result.data = ~lhs.data
    return result
}

// tell if itstrue
// @param cond
// @return bool
fn isTrue(cond<Value>){
    if cond == False {
        dief(*"isTrue: cond is null ,something wrong  probably")
    }
    match cond.type {
        Int:    return cond.data > 0
        Float: {
            cond2<FloatValue> = cond
            return cond2.data > 0
        }
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
fn operator_switch(opt<i32>,lhs<Value>,rhs<Value>){
    if rhs == null {
        if opt != LOGNOT && opt != BITNOT {
            dief(*"[operator] only !,~ at unary expression,not:%d\n",opt)
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
            println(*"[unary-op] unknown opt:%d" ,opt)
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
fn unary_operator(opt<i32>,lhs<u64*>,rhs<Value>)
{
    //lhs == Value**
    if lhs == null  {
        dief(*"[unary-op] %s lhs arg is null",token_string(opt))
    }
    if rhs == null {
        dief(*"[unary-op] %s rhs arg is null",token_string(opt))
    }
    ret<Value> = operator_switch(opt,*lhs,rhs)
    //*(Value**)lhs = ret
    *lhs = ret
    return ret
}

// lhs  rhs
// rhs == null
// @param opt
// @param lhs
// @param rhs
fn binary_operator(opt<i32>, lhs<Value>, rhs<Value>)
{
    if lhs == null {
        dief(
            *"[binary-op] op:%s probably wrong at there!",
            token_string(opt)
        )
    }
    ret<Value> = operator_switch(opt,lhs,rhs)
    if ret.data == 1 && ret.type == String 
        println(*"[binaryop] something error") 
    
    return ret
}

fn miss_args(pos<i32>,fname<i8*>,isclass<i8>){
    // str = string.new(fname)
    if isclass {
        pos -= 1
    }
    if isclass && pos == 0 {
        printf(*"[warn] Missing first argument \'this\' for class memthod %s()\n",fname)
        return Null
    }
    printf(*"[warn] Missing argument %d for %s()\n",pos,fname)
}
fn check_object(obj<Value>){
    if obj == Null return Null
    if obj.type == Null return Null
    return True
}
fn miss_objects(filename<i8*>,funcname<i8*>,line<i32>,column<i32>){
    dief(
        *"[error] call to undefined method %s in %s on line  %d column %d\n",
        funcname,
        filename,
        line,column
    )
}

fn get_float_v(v<Value>){
    ret<f64> = 0
    match v.type {
        Float : ret = v.(FloatValue).data
        Int :   ret = v.data
        Bool :  ret = v.data
        Char :  ret = v.data
        _ : println(*"[warn] unsupport type in float op")
    }
    return ret
}
//   value op int | float
// +
fn value_int_plus(lhs<Value>,rhs<Value>){
    return lhs.data + rhs.data
}
fn value_float_plus(lhs<Value>,rhs<Value>){
    l<f64> = get_float_v(lhs)
    r<f64> = get_float_v(rhs)
    return l + r
}
// -
fn value_int_minus(lhs<Value>,rhs<Value>){
    return lhs.data - rhs.data
}
fn value_float_minus(lhs<Value>,rhs<Value>){
    l<f64> = get_float_v(lhs)
    r<f64> = get_float_v(rhs)
    return l - r
}
// *
fn value_int_mul(lhs<Value>,rhs<Value>){
    return lhs.data * rhs.data
}
fn value_float_mul(lhs<Value>,rhs<Value>){
    l<f64> = get_float_v(lhs)
    r<f64> = get_float_v(rhs)
    return l * r
}
// /
fn value_int_div(lhs<Value>,rhs<Value>){
    return lhs.data / rhs.data
}
fn value_float_div(lhs<Value>,rhs<Value>){
    l<f64> = get_float_v(lhs)
    r<f64> = get_float_v(rhs)
    return l / r
}
// &
fn value_int_bitand(lhs<Value>,rhs<Value>){
    return lhs.data & rhs.data
}
// |
fn value_int_bitor(lhs<Value>,rhs<Value>){
    return lhs.data | rhs.data
}
fn value_int_bitxor(lhs<Value>,rhs<Value>){
    return lhs.data ^ rhs.data
}
// <<
fn value_int_shift_left(lhs<Value>,rhs<Value>){
    return lhs.data << rhs.data
}
// >>
fn value_int_shift_right(lhs<Value>,rhs<Value>){
    return lhs.data >> rhs.data
}
// ==
fn value_int_equal(lhs<Value>,rhs<Value>,equal<i32>){
    if equal	return lhs.data == rhs.data
    else		return lhs.data != rhs.data
}
fn value_float_equal(lhs<Value>,rhs<Value>,equal<i32>){
    l<f64> = get_float_v(lhs)
    r<f64> = get_float_v(rhs)
    if equal	return l == r
    else		return l != r
}
// !=
fn value_int_notequal(lhs<Value>,rhs<Value>){
    return lhs.data != rhs.data
}
// <
fn value_int_lowerthan(lhs<Value>,rhs<Value>,equal<i32>){
    if equal	return lhs.data <= rhs.data
    else		return lhs.data < rhs.data
}
fn value_float_lowerthan(lhs<Value>,rhs<Value>,equal<i32>){
    l<f64> = get_float_v(lhs)
    r<f64> = get_float_v(rhs)
    if equal	return l <= r
    else		return l < r
}
// >
fn value_int_greaterthan(lhs<Value>,rhs<Value>,equal<i32>){
    if equal	return lhs.data >= rhs.data
    else		return lhs.data > rhs.data
}
fn value_float_greaterthan(lhs<Value>,rhs<Value>,equal<i32>){
    l<f64> = get_float_v(lhs)
    r<f64> = get_float_v(rhs)
    if equal	return l >= r
    else		return l > r
}

//   value op string
fn value_string_plus(lhs<Value>,rhs<Value>)
{
    tmstr<string.Str> = string.empty()
    match lhs.type 
	{
		Int   : tmstr = tmstr.catfmt(*"%I%S",lhs.data,rhs.data)
		Bool  : tmstr = tmstr.catfmt(*"%I%S",lhs.data,rhs.data)
        Float : tmstr = tmstr.catfmt(*"%I%S",lhs.data,rhs.data)
        String: {
            tmstr = lhs.data.(string.Str).dup()
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

fn value_string_minus(lhs<Value>,rhs<Value>)
{
    match lhs.type {
        String : return lhs.data
        _      : return rhs.data
    }
}

fn value_string_mul(lhs<Value>,rhs<Value>)
{
    if lhs.type == String && rhs.type == String {
        tmstr<string.Str> = rhs.data.(string.Str).dup()
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
        tmstr<string.Str> = srcv.data.(string.Str).dup()
        count -= 1
        for (i<i64> = 0 ; i < count ; i += 1) {
            tmstr = tmstr.cat(srcv.data)
        }
        return tmstr
    }
    //has char
    match lhs.type {
        Char : {
            tmstr<string.Str> = string.empty()
            tmstr = tmstr.putc(lhs.data)
            tmstr = tmstr.cat(rhs.data)
            return tmstr
        }
        String:{
            match rhs.type {
                Char :{
                    tmstr<string.Str> = lhs.data.(string.Str).dup()
                    tmstr = tmstr.putc(rhs.data)
                    return tmstr
                }
                _: dief(*"[string *] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
            }
        }
        _: dief(*"[string *] unknown type: lhs:%s rhs:%s" , type_string(lhs) , type_string(rhs))
    }
}
//char int
fn value_char2int_mul(lhs<Value>,rhs<Value>){
    tmstr<string.Str> = string.empty()
    for (i<i64> = 0 ; i < rhs.data ; i += 1) {
        tmstr = tmstr.putc(lhs.data)
    }
    return tmstr
}
//char char
fn value_char2char_mul(lhs<Value>,rhs<Value>){
    tmstr<string.Str> = string.empty()

    tmstr = tmstr.putc(lhs.data)
    tmstr = tmstr.putc(rhs.data)
    return tmstr
}

fn value_string_div(lhs<Value>,rhs<Value>){
    return Null
}
fn value_string_bitand(lhs<Value>,rhs<Value>){
    return Null
}
fn value_string_bitor(lhs<Value>,rhs<Value>){
    return Null
}
fn value_string_bitxor(lhs<Value>,rhs<Value>){
    return Null
}
fn value_string_shift_left(lhs<Value>,rhs<Value>){
    return Null
}
fn value_string_shift_right(lhs<Value>,rhs<Value>){
    return Null
}
fn value_string_equal(lhs<Value>,rhs<Value>,equal<i32>){
    if lhs.type != String || rhs.type != String {
        if equal return False
        else return True
    }
    //TODO: if _stringcmp(..) == 0 {}
    ret<i8> = lhs.data.(string.Str).cmp(rhs.data)
    if ret == 0 {
        if equal return True
        else return False
    }
    if equal return False
    else return True

}
//< <=
fn value_string_lowerthan(lhs<Value>,rhs<Value>,equal<i32>){
    if lhs.type != String || rhs.type != String {
        return False
    }
    eq<i32> = lhs.data.(string.Str).cmp(rhs.data) 
    if equal {
        return eq <= 0
    }
    return eq < 0
}
//> >=
fn value_string_greaterthan(lhs<Value>,rhs<Value>,equal<i32>){
    if lhs.type != String || rhs.type != String {
        return False
    }
    eq<i32> = lhs.data.(string.Str).cmp(rhs.data) 
    if equal return eq >= 0
    return eq > 0
}
