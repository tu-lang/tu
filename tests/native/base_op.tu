use fmt

gvar<T1:1>
mem T1 {
	i8 a,b,d
	i8 c[3]
}
p<T1> = &gvar
//1. test reference global stack
//2. test global var stack
func test_ref_global_var(){
	//test reference global stack var gvar
	p2<T1> = &gvar
	p2.d = 11
	p2.c[0] = 22
	p2.c[1] = 33
	p2.c[2] = 44

	if p2.d == 11 {} else os.die("p2.d != 11")
	if p2.c[0] == 22 {} else os.die("p2.c[0] != 22")
	if p2.c[1] == 33 {} else os.die("p2.c[0] != 33")
	if p2.c[2] == 44 {} else os.die("p2.c[0] != 44")
	//test global p
	if p.d == 11 {} else os.die("p.d != 11")
	if p.c[0] == 22 {} else os.die("p.c[0] != 22")
	if p.c[1] == 33 {} else os.die("p.c[0] != 33")
	if p.c[2] == 44 {} else os.die("p.c[0] != 44")

	fmt.println("test ref global var&& global stack var success")
}
func test_i8_i32_mixed(){
	a<i8> = -5
	if a < 0 {} else os.die("-5 < 0")
	b<i32> = 5
	c<u8> = 14
	r<i32> = a + ( b % c)
	if r == 0 {} else os.die(" -5 + ( 5 % 15)  != 0")
	fmt.println("test_i_i32_mixed success")
}

// Operand struct for unary minus on fields / members.
mem NegM {
	i32 a
	f64 f
	i64 b
	i8  c
}
NegM::neg() i32 { return -this.a }
NegM::negf() f64 { return -this.f * 2.0 }
fn neg_i(x<i32>) i32 { return x }
fn neg_f(x<f64>) f64 { return x }
fn neg_ret(x<i64>) i64 { return -x }

// Unary minus on non-literal static operands: vars, calls, fields, nesting.
func test_negate_static(){
	a<i32> = 5
	b<i64> = 9
	c<i8> = 3
	f<f64> = 1.5
	g<f32> = 2.5
	u<u8> = 1
	m<NegM> = new NegM{a: 7, f: 2.25, b: 11, c: -2}
	// variables of every width
	if -a != -5 os.die("-a")
	if -b != -9 os.die("-b")
	if int(-c) != -3 os.die("-c")
	nc<i8> = -m.c
	if int(nc) != 2 os.die("-m.c")
	// call results
	n<i32> = -neg_i(4)
	if n != -4 os.die("-neg_i()")
	if -neg_i(a) * 2 != -10 os.die("-neg_i(a) * 2")
	if neg_ret(b) != -9 os.die("return -x")
	if -neg_ret(3) != 3 os.die("-neg_ret()")
	// fields and member calls
	if -m.a != -7 os.die("-m.a")
	if -m.b * 2 != -22 os.die("-m.b * 2")
	if m.neg() != -7 os.die("m.neg()")
	if -m.neg() != 7 os.die("-m.neg()")
	// nesting / binary contexts
	if -(-a) != 5 os.die("-(-a)")
	if a * -a != -25 os.die("a * -a")
	if -a + 10 != 5 os.die("-a + 10")
	if a - -a != 10 os.die("a - -a")
	if -(a + b) != -14 os.die("-(a + b)")
	// compound assignment / loop
	t<i32> = 0
	t += -a
	t -= -m.a
	if t != 2 os.die("t += -a")
	s<i32> = 0
	for i<i32> = 0 ; i < 3 ; i += 1 {
		s += -i
	}
	if s != -3 os.die("s += -i")
	// floats
	nf1<f64> = -f
	if nf1 != -1.5 os.die("-f")
	nf2<f64> = -neg_f(0.5) + 1.0
	if nf2 != 0.5 os.die("-neg_f()")
	nf3<f64> = -m.f
	if nf3 != -2.25 os.die("-m.f")
	if m.negf() != -4.5 os.die("m.negf()")
	ng<f32> = -g
	if ng != -2.5 os.die("-g")
	// unsigned wraps like 0 - u
	w<u8> = 0 - u
	nu<u8> = -u
	if nu != w os.die("-u")
	fmt.println("test_negate_static success")
}

func main(){
	test_ref_global_var()
	test_i8_i32_mixed()
	test_negate_static()
}