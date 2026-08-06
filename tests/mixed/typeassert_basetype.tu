use fmt

_EAGAIN_TEST<i64> = 0xb

func test_int(){
	num = 376.(i8)
	_tmp<i32> = 376

	if _tmp == num {} else os.die("num should be 376 static")

	if int(num) == 376 {} else os.die("num should be 376")

	fc = func(v<i32>){
		if v == 444 {} else os.die("v should b 444")
	}
	fc(444.(i32))
	fmt.println("test_int success")
}
func test_char(){
	c = 'd'.(i8)
	_t<i32> = 'd'
	if _t == c {} else os.die("c != d")

	fc = func(v<i32>){
		if v == 'x'  {} else os.die(" v != x")
	}
	fc('x'.(i8))
	fmt.println("test_char success")
}
func test_string(){
	str = "45ss54".(i8)
	if string.new(str) == "45ss54" {} else os.die("str != 45ss54")
	fmt.println("test string success")
}
// Parenthesized BinaryExpr + chain-end .(T): scalar cast, must not enter memgen.
// Operands must be native (typed var / i64 const); bare IntExpr pairs stay dynamic.
func test_binary_neg_cast(){
	a<i32> = 0
	b<i32> = 1
	v1<i32> = (a - b).(i32)
	expect1<i32> = a - b
	if v1 != expect1 {
		os.die(" (a - b).(i32) mismatch")
	}
	v2<i32> = (0 - _EAGAIN_TEST).(i32)
	expect2<i32> = 0 - _EAGAIN_TEST
	if v2 != expect2 {
		os.die(" (0 - const).(i32) mismatch")
	}
	c<i32> = 1
	d<i32> = 2
	v3<i32> = (c + d).(i32)
	expect3<i32> = 3
	if v3 != expect3 {
		os.die(" (c + d).(i32) mismatch")
	}
	// Compare against syscall-style negative errno form.
	ret<i32> = 0 - _EAGAIN_TEST
	if ret != (0 - _EAGAIN_TEST).(i32) {
		os.die(" ret != (0 - const).(i32)")
	}
	fmt.println("test_binary_neg_cast success")
}

// Package-level const typed scalars must load as values (mov imm), not lea addresses.
const PKG_CONST_HDR<i32> = 24
const PKG_CONST_REC<i32> = 40
func test_pkg_typed_const_rvalue(){
	sum<i32> = PKG_CONST_HDR + PKG_CONST_REC
	if sum != 64 {
		os.die("PKG_CONST_HDR + PKG_CONST_REC should be 64")
	}
	prod<i32> = PKG_CONST_HDR * 2
	if prod != 48 {
		os.die("PKG_CONST_HDR * 2 should be 48")
	}
	if PKG_CONST_REC < 100 {
	} else {
		os.die("PKG_CONST_REC < 100 should hold")
	}
	fmt.println("test_pkg_typed_const_rvalue success")
}
func main(){
	test_int()
	test_char()
	test_string()
	test_binary_neg_cast()
	test_pkg_typed_const_rvalue()
}
