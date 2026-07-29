use fmt
use os
use std
use runtime

fn offsetof(ptr1<i64> , ptr2<i64>){
	return ptr2  - ptr1
}

// Mixed-width probe for sizeof(Mem) alongside primitives in one layout.
mem SizeProbe {
	u32 events
	u64 token
}

// Every i8..f64 primitive: compile-time constant and compare/codegen paths.
fn test8(){
	fmt.println("test8 primitive sizeof")

	if sizeof(i8) != 1 os.die("sizeof i8")
	if sizeof(i16) != 2 os.die("sizeof i16")
	if sizeof(i32) != 4 os.die("sizeof i32")
	if sizeof(i64) != 8 os.die("sizeof i64")
	if sizeof(u8) != 1 os.die("sizeof u8")
	if sizeof(u16) != 2 os.die("sizeof u16")
	if sizeof(u32) != 4 os.die("sizeof u32")
	if sizeof(u64) != 8 os.die("sizeof u64")
	if sizeof(f32) != 4 os.die("sizeof f32")
	if sizeof(f64) != 8 os.die("sizeof f64")

	// == branch (not only !=) exercises binary compare codegen on builtins.
	if sizeof(u64) == 8 {} else os.die("sizeof u64 eq")
	if sizeof(f32) == 4 {} else os.die("sizeof f32 eq")

	sz<i32> = sizeof(i64)
	if sz != 8 os.die("sizeof assign i64")

	fmt.println("test8 primitive sizeof success")
}

// sizeof in arithmetic, mem scaling, and malloc — patterns used by asyncio/runtime.
fn test9(){
	fmt.println("test9 sizeof arith and malloc")

	if sizeof(u32) + sizeof(i32) != 8 os.die("primitive add")
	if sizeof(u64) * 2 != 16 os.die("primitive mul literal")
	n<u64> = 4
	if sizeof(u64) * n != 32 os.die("primitive mul var")
	if sizeof(SizeProbe) != 16 os.die("sizeof SizeProbe")
	if sizeof(Demo) != 8 os.die("sizeof Demo")

	p<u64> = runtime.malloc(sizeof(u64) * n, 0.(i8), 1.(i8))
	if p == 0 os.die("malloc sizeof u64 scale")
	q<u64> = runtime.malloc(sizeof(SizeProbe) * 2, 0.(i8), 1.(i8))
	if q == 0 os.die("malloc sizeof mem scale")
	r<u64> = runtime.malloc(sizeof(Demo) + sizeof(u32), 0.(i8), 1.(i8))
	if r == 0 os.die("malloc sizeof mixed add")

	// Mem sizeof still works in the same function as primitive sizeof.
	if sizeof(T1) == 8 {} else os.die("sizeof T1 beside primitive")

	fmt.println("test9 sizeof arith and malloc success")
}

mem T1 {
	i8 a
	i8 b
}
mem T1P: pack {
	i8 a
	i8 b
}
fn test1(){
	fmt.println("test 1")

	if sizeof(T1) == 8  {} else os.die("t1 != 8")
	p<T1> = new T1 {}
	of<i64> = offsetof(p,&p.b)
	if of != 1 os.die("t1.b != 1")

	//pack
	if sizeof(T1P) == 2  {} else os.die("t1p != 2")
	p1<T1P> = new T1P{}
	of = offsetof(p1,&p1.b)
	if of != 1 os.die("t1p.b != 1")
	fmt.println("test 1 success")
}
mem T2 {
	i8 a 
	i8* b
	i8 c
}
mem T2P:pack {
	i8 a 
	i8* b
	i8 c
}

// Preserves full native pointer bits in typed and raw mem fields.
mem PointerFieldRoundTrip {
	u8* ptr_slot
	u64 bits_slot
}

// Guards against narrowing a 64-bit pointer through signed 32-bit codegen.
fn test_pointer_field_roundtrip(){
	fmt.println("test pointer field roundtrip")
	raw<u64> = runtime.malloc(64, 0.(i8), 1.(i8))
	if raw == 0 os.die("pointer field malloc failed")
	p<u8*> = raw
	h<PointerFieldRoundTrip> = new PointerFieldRoundTrip
	h.ptr_slot = p
	h.bits_slot = p

	back_ptr<u8*> = h.ptr_slot
	back_ptr_bits<u64> = back_ptr
	back_bits<u64> = h.bits_slot
	if back_ptr_bits != raw os.die("pointer field truncated")
	if back_bits != raw os.die("u64 field truncated")
	fmt.println("test pointer field roundtrip success")
}

// By-value nested mem: payload must be copied into the outer layout,
// not stored as a heap pointer in the field slot (optimize debt §9).
mem NestedInner {
	u64 bits
	u32 tag
}
mem NestedOuter {
	NestedInner nest
	u64 marker
}

fn test_nested_mem_value_copy(){
	fmt.println("test nested mem value copy")

	// Baseline: scalar writes into the embedded layout.
	o0<NestedOuter> = new NestedOuter
	o0.nest.bits = 1111.(u64)
	o0.nest.tag = 7.(u32)
	o0.marker = 9.(u64)
	if o0.nest.bits != 1111.(u64) os.die("scalar nest.bits != 1111")
	if o0.nest.tag != 7.(u32) os.die("scalar nest.tag != 7")
	if o0.marker != 9.(u64) os.die("scalar marker != 9")

	// Assign `new Inner{...}` into a by-value nested field.
	o1<NestedOuter> = new NestedOuter
	o1.nest = new NestedInner { bits: 2222.(u64), tag: 8.(u32) }
	o1.marker = 1.(u64)
	if o1.nest.bits != 2222.(u64) os.die("assign-new nest.bits != 2222")
	if o1.nest.tag != 8.(u32) os.die("assign-new nest.tag != 8")
	if o1.marker != 1.(u64) os.die("assign-new marker != 1")

	// Struct literal with nested `new Inner{...}`.
	o2<NestedOuter> = new NestedOuter {
		nest: new NestedInner { bits: 3333.(u64), tag: 9.(u32) },
		marker: 2.(u64),
	}
	if o2.nest.bits != 3333.(u64) os.die("literal nest.bits != 3333")
	if o2.nest.tag != 9.(u32) os.die("literal nest.tag != 9")
	if o2.marker != 2.(u64) os.die("literal marker != 2")

	// Copy from an existing Inner heap object into the nested slot.
	inn<NestedInner> = new NestedInner { bits: 4444.(u64), tag: 10.(u32) }
	o3<NestedOuter> = new NestedOuter
	o3.nest = inn
	o3.marker = 3.(u64)
	if o3.nest.bits != 4444.(u64) os.die("copy-var nest.bits != 4444")
	if o3.nest.tag != 10.(u32) os.die("copy-var nest.tag != 10")
	if o3.marker != 3.(u64) os.die("copy-var marker != 3")

	// In-place nested StructInitExpr (no `new` on the inner literal).
	o4<NestedOuter> = new NestedOuter {
		nest: NestedInner { bits: 5555.(u64), tag: 11.(u32) },
		marker: 4.(u64),
	}
	if o4.nest.bits != 5555.(u64) os.die("inplace nest.bits != 5555")
	if o4.nest.tag != 11.(u32) os.die("inplace nest.tag != 11")
	if o4.marker != 4.(u64) os.die("inplace marker != 4")

	fmt.println("test nested mem value copy success")
}

mem NullBox {
	i32 tag
}

mem NullList {
	u64 front_bits
	u64 back_bits
}

NullList::front_entry() NullBox {
	bits<u64> = this.front_bits
	if bits == 0 return null
	return bits.(NullBox)
}

fn take_null_box(b<NullBox>){
	if b != null os.die("take_null_box should receive null")
}

fn test_mem_return_null(){
	fmt.println("test mem return null")

	l<NullList> = new NullList
	l.front_bits = 0
	l.back_bits = 0
	if l.front_entry() != null os.die("empty front_entry should be null")

	t<NullBox> = new NullBox { tag: 9 }
	bits<u64> = 0
	bits = t
	l.front_bits = bits
	e<NullBox> = l.front_entry()
	if e == null os.die("nonempty front_entry should not be null")
	if e.tag != 9 os.die("front_entry tag != 9")

	take_null_box(null)
	fmt.println("test mem return null passed")
}

fn test2(){
	fmt.println("test 2")

	if sizeof(T2) == 24 {} else os.die("t2 != 24")	
	p<T2> = new T2{}
	ofb<i64> = offsetof(p,&p.b)
	ofc<i64> = offsetof(p,&p.c)
	if ofb == 8 {} else os.die("ofb != 8")
	if ofc == 16{} else os.die("ofc != 16")

	if sizeof(T2P) == 10 {} else os.die("t2p != 10")
	p2<T2P> = new T2P{}
	ofb = offsetof(p2,&p2.b)
	ofc = offsetof(p2,&p2.c)
	if ofb == 1 {} else os.die("ofb != 1")
	if ofc == 9 {} else os.die("ofc != 9")
	fmt.println("test 2 success")
}

mem T3_1 {
	i8 a
	i8* b
	i8* c
}
mem T3 {
	i8 a 
	T3_1 b
	i8 c
}
fn test3(){
	fmt.println("test 3")
	if sizeof(T3) == 40 {} else os.die("t3 != 40")
	p<T3> = new T3{}

	ofbb<i64> = offsetof(p,&p.b.b)
	ofc<i64>  = offsetof(p,&p.c)
	if ofbb == 16 {} else os.die("t3.b.b != 16")
	if ofc == 32 {} else os.die("ofc != 32")
	if sizeof(T3P) == 12 {} else os.die("t3p != 12")
	p2<T3P> = new T3P{}
	ofbb = offsetof(p2,&p2.b.b)
	ofc  = offsetof(p2,&p2.c)
	if ofbb == 2 {} else os.die("t3p.b.b != 2")
	if ofc == 11 {} else os.die("t3p.ofc != 11")

	fmt.println("test 3 success")
}
mem T3_1P:pack {
	i8 a
	i8* b
	i8 c
}
mem T3P:pack {
	i8 a 
	T3_1P b
	i8 c
}

mem T4_1 {
	i8 a
	i8* b
	i8 c
}
mem T4P:pack {
	i8 a 
	T4_1 b
	i8 c
}

fn test4(){
	fmt.println("test 4")
	p<T4P> = new T4P{}
	if sizeof(T4P) == 26 {} else os.die("t4p != 26")
	offbb<i64> = offsetof(p,&p.b.b)
	offc<i64> = offsetof(p,&p.c)
	if offbb == 9 {} else os.die("offb != 9")
	if offc == 25 {} else os.die("offc != 25")

	fmt.println("test 4 success")
}
mem T5_1P:pack {
	i8 a
	i8* b
	i8 c
}
mem T5 {
	i8 a 
	T5_1P b
	i8 c
}

fn test5(){
	fmt.println("test 5")
	p<T5> = new T5{}
	offbb<i64> = offsetof(p,&p.b.b)
	offc<i64> = offsetof(p,&p.c)
	if sizeof(T5) == 16 {} else os.die("t5 != 26")
	if offbb == 2 {} else os.die("offb != 9")
	if offc == 11 {} else os.die("offc != 25")

	fmt.println("test 5 success")
}

mem Demo {
	i32 a
	f32 b
}
const Demo::new(a<i32>,b<f32>) Demo {
	return new Demo {
		a: a,
		b: b
	}
}
const Demo::new2() {
	return "new2"
}
fn test6(){
	fmt.println("test current static fn")
	b<f32> = 22.2
	p<Demo> = Demo::new(111.(i32),b)
	if p.a == 111 {} else os.die("neq 111")
	if p.b > 22.2 && p.b < 22.3 {} else os.die("neq 22.2")

	if Demo::new(222.(i32),b).a == 222 {} else os.die("neq 111")
	if Demo::new(222.(i32),b).b > 22.2 && Demo::new(222.(i32),b).b < 22.3 {} else os.die("neq 22.2")

	if Demo::new2() == "new2" {} else os.die("neq new2")
	fmt.println("test current static fn success")
}
// Multi-return const static members: values after the first must survive
// multi-assign (regression: static_compile freed the return stack early and
// a placeholder push shifted StackPosExpr reads onto garbage).
const Demo::pair(a<i32>) (i32, u64, i32) {
	bits<u64> = 8888
	return a, bits, 42
}
fn test10(){
	fmt.println("test static fn multi return")
	e<i32>, b<u64>, c<i32> = Demo::pair(7)
	if e == 7 {} else os.die("pair first != 7")
	if b == 8888 {} else os.die("pair second != 8888")
	if c == 42 {} else os.die("pair third != 42")
	// heap pointer as second value must stay dereferenceable
	f<f32> = 22.2
	e2<i32>, d2<u64> = Demo::boxed(9,f)
	if e2 == 1 {} else os.die("boxed first != 1")
	dd<Demo> = d2.(Demo)
	if dd.a == 9 {} else os.die("boxed .a != 9")
	fmt.println("test static fn multi return success")
}
const Demo::boxed(a<i32>,b<f32>) (i32, u64) {
	d<Demo> = new Demo { a: a, b: b }
	return 1, d.(u64)
}
// Instance-member multi-return (obj / chain receiver): values after the
// first must survive multi-assign too (regression: the parked receiver
// slot sat under the return block and load was hardcoded true).
Demo::ipair(x<i32>) (i32, u64) {
	bits<u64> = 6666
	return x, bits
}
// Receiver identity: with multi-return the reserved return slots sit between
// the parked receiver and the args, so the ArgsPosExpr offset must count
// them (regression: callee `this` pointed at the return-stack address).
Demo::iself(x<i32>, y<u64>) (i32, u64) {
	return this.a + x, y
}
mem DemoHolder {
	Demo* held
}
DemoHolder::run() (i32, u64) {
	e<i32> = 0
	b<u64> = 0
	e, b = this.held.ipair(5)
	return e, b
}
DemoHolder::run2() (i32, u64) {
	e<i32>, b<u64> = this.held.iself(20, 555)
	return e, b
}
fn test11(){
	fmt.println("test member fn multi return")
	f<f32> = 1.5
	dv<Demo> = Demo::new(3,f)
	e<i32>, b<u64> = dv.ipair(4)
	if e == 4 {} else os.die("ipair direct first != 4")
	if b == 6666 {} else os.die("ipair direct second != 6666")
	h<DemoHolder> = new DemoHolder { held: dv }
	e2<i32>, b2<u64> = h.run()
	if e2 == 5 {} else os.die("ipair chained first != 5")
	if b2 == 6666 {} else os.die("ipair chained second != 6666")
	// receiver fields must be readable inside a multi-return member fn
	e3<i32>, b3<u64> = dv.iself(1, 777)
	if e3 == 4 {} else os.die("iself direct first != 4")
	if b3 == 777 {} else os.die("iself direct second != 777")
	e4<i32>, b4<u64> = h.run2()
	if e4 == 23 {} else os.die("iself chained first != 23")
	if b4 == 555 {} else os.die("iself chained second != 555")
	fmt.println("test member fn multi return success")
}
use pkg
fn test7(){
	fmt.println("test external static fn")
	b<f32> = 22.2
	p<pkg.Demo> = pkg.Demo::new(111.(i32))
	if p.a == 111 {} else os.die("neq 111")
	if p.b > 333.2 && p.b < 333.4 {} else os.die("neq 333.3")

	if pkg.Demo::new(222.(i32)).a == 222 {} else os.die("neq 111")
	if pkg.Demo::new(222.(i32)).b > 333.2 && pkg.Demo::new(222.(i32)).b < 333.4 {} else os.die("neq 22.2")
	if pkg.Demo::new2() == "new2" {} else os.die("neq new2")
	fmt.println("test external static fn success")
}
fn main(){
	test8()
	test9()
	test1()
	test2()
	test3()
	test4()
	test5()
	test6()
	test7()
	test10()
	test11()
	test_pointer_field_roundtrip()
	test_nested_mem_value_copy()
	test_mem_return_null()
}