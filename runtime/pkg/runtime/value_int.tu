
// +
func value_int_plus(lhs<Value>,rhs<Value>){
    return lhs.data + rhs.data
}
// -
func value_int_minus(lhs<Value>,rhs<Value>){
    return lhs.data - rhs.data
}
// *
func value_int_mul(lhs<Value>,rhs<Value>){
    return lhs.data * rhs.data
}
// /
func value_int_div(lhs<Value>,rhs<Value>){
    return lhs.data / rhs.data
}
// &
func value_int_bitand(lhs<Value>,rhs<Value>){
    return lhs.data & rhs.data
}
// |
func value_int_bitor(lhs<Value>,rhs<Value>){
    return lhs.data | rhs.data
}
// <<
func value_int_shift_left(lhs<Value>,rhs<Value>){
    return lhs.data << rhs.data
}
// >>
func value_int_shift_right(lhs<Value>,rhs<Value>){
    return lhs.data >> rhs.data
}
// ==
func value_int_equal(lhs<Value>,rhs<Value>,equal<i32>){
    if equal	return lhs.data == rhs.data
    else		return lhs.data != rhs.data
}
// !=
func value_int_notequal(lhs<Value>,rhs<Value>){
    return lhs.data != rhs.data
}
// <
func value_int_lowerthan(lhs<Value>,rhs<Value>,equal<i32>){
    if equal	return lhs.data <= rhs.data
    else		return lhs.data < rhs.data
}
// >
func value_int_greaterthan(lhs<Value>,rhs<Value>,equal<i32>){
    if equal	return lhs.data >= rhs.data
    else		return lhs.data > rhs.data
}