use fmt
use os

class A {
	var = 10
	next
	arr = []
	func getvar(){
		return this.var
	}
	func setvar(var){
		this.var = var
	}
	func getthis(){return this}
}
func test_chain_member(){
	obj = new A()
	if obj.var != 10 os.die("obj.var != 10")
	if obj.getvar() != 10 os.die("obj.var != 10")

	obj.next = new A()
	obj.next.var = 20
	if obj.next.var != 20 os.die("obj.next.var != 20")
	obj.next.setvar(30)
	if obj.next.getvar() != 30 os.die("obj.next.getvar() != 30")

	obj.next.arr[] = 500 
	obj.next.arr[0] = 501
	if obj.next.arr[0] == 501 {} else {
		os.die("obj.next.arr[0] != 501")
	}
	obj.next.arr[] = new A()
	obj.next.arr[1].setvar(500)
	if obj.next.arr[1].getvar() == 500 {} else {
		os.die("obj.next.arr[1].getvar() != 500")
	}
	if obj.next.arr[1].getthis().var == 500 {} else {
		os.die("obj.next.arr[0].getthis().var != 500")
	}
	fmt.println("test chain member success")
}
func test_chain_arr(){
	arr = [[new A()]]
	arr[0][0].getthis().setvar("test")
	if arr[0][0].getthis().getvar() == "test" {} else {
		os.die("should be test")
	}
	arr[0][0] = 500
	if arr[0][0] == 500 {} else {
		os.die("arr[0][0] != 500")
	}
	fmt.println("test chain arr success")
}
class B {
	arr = [100,333]
	func getarr(i){
		return this.arr[i]
	}
}
func test_complex(){
	if (new B()).arr[0] != 100 {
		os.die("arr[0] should be 100")
	}
	if (new B()).getarr(1) != 333 {
		os.die("arr[1] should be 333")
	}
	fmt.println("test complex situation success")
}

// Chain calls whose callee returns multiple values: the receiver must stay
// reachable as `this` and the full return group must survive multi-assign.
class Pair {
	tag = 0
	next
	func init(t){ this.tag = t }
	func two(x){ return x, x + 1 }
	func who(){ return this.tag, this.tag * 2 }
	func three(a, b){ return a, b, this.tag }
	func one(){ return this.tag }
	func self(){ return this }
	func selfpair(){ return this, this.tag }
	func depth(n){
		if n == 0 return 0, this.tag
		a, b = this.next.depth(n - 1)
		return a + 1, b
	}
}
class Holder {
	cur
	arr
	m
	inner
	func init(){
		this.cur = new Pair(7)
		this.arr = [new Pair(8)]
		this.m = {"k": new Pair(9)}
	}
	func viaThis(x){
		a, b = this.cur.two(x)
		return a, b
	}
	func whoThis(){
		a, b = this.cur.who()
		return a, b
	}
	func forward(){ return this.cur.who() }
	func forward3(){ return this.cur.three(1, 2) }
	func firstOnly(){
		a = this.cur.who()
		return a
	}
}
func mk(t){ return new Pair(t) }
func add2(a, b){ return a + b }

// Package-level initializers run inside the generated init function.
g_chain_one = mk(11).one()
g_chain_first = mk(12).who()

// Member defaults are evaluated inside the class init function, so their
// chain receiver slots must be registered there (with and without a father).
class ChainDefaults {
	one = mk(31).one()
	first = mk(32).who()
	sum = add2(mk(33).one(), mk(34).one())
}
class ChainDefaultsChild : ChainDefaults {
	extra = mk(35).self().one()
	func init(){ super.init() }
}

func test_chain_multiret_receivers(){
	h = new Holder()
	a, b = h.viaThis(5)
	if a != 5 || b != 6 os.dief("this.cur.two: %d %d", a, b)
	a, b = h.whoThis()
	if a != 7 || b != 14 os.dief("this.cur.who: %d %d", a, b)

	a, b = h.cur.who()
	if a != 7 || b != 14 os.dief("h.cur.who: %d %d", a, b)
	a, b = mk(5).who()
	if a != 5 || b != 10 os.dief("mk().who: %d %d", a, b)
	a, b = h.arr[0].who()
	if a != 8 || b != 16 os.dief("arr[0].who: %d %d", a, b)
	a, b = h.m["k"].who()
	if a != 9 || b != 18 os.dief("m[k].who: %d %d", a, b)

	h.inner = new Holder()
	h.inner.cur = new Pair(21)
	a, b = h.inner.cur.who()
	if a != 21 || b != 42 os.dief("h.inner.cur.who: %d %d", a, b)
	a, b = h.cur.self().who()
	if a != 7 || b != 14 os.dief("cur.self().who: %d %d", a, b)

	x, y, z = h.cur.three(1, 2)
	if x != 1 || y != 2 || z != 7 os.dief("cur.three: %d %d %d", x, y, z)
	fmt.println("test chain multiret receivers success")
}

func test_chain_multiret_contexts(){
	h = new Holder()
	// Single receive keeps the first value.
	a = h.cur.who()
	if a != 7 os.dief("single receive: %d", a)
	if h.firstOnly() != 7 os.die("firstOnly != 7")

	// return callee() forwards the whole group.
	a, b = h.forward()
	if a != 7 || b != 14 os.dief("forward: %d %d", a, b)
	x, y, z = h.forward3()
	if x != 1 || y != 2 || z != 7 os.dief("forward3: %d %d %d", x, y, z)

	// Intermediate chain node returning multiple values.
	if mk(3).selfpair().one() != 3 os.die("selfpair().one() != 3")

	// Condition / compound assign / call argument / match.
	if h.cur.one() == 7 {} else os.die("if cur.one() != 7")
	s = 1
	s += h.cur.one()
	if s != 8 os.dief("+= cur.one(): %d", s)
	if add2(h.cur.one(), mk(2).one()) != 9 os.die("add2 chain args != 9")
	match h.cur.one() {
		7 : {}
		_ : os.die("match cur.one() != 7")
	}

	// Chain calls nested inside the arguments of another chain call.
	x, y, z = h.cur.three(mk(4).one(), h.arr[0].one())
	if x != 4 || y != 8 || z != 7 os.dief("nested args: %d %d %d", x, y, z)
	fmt.println("test chain multiret contexts success")
}

func test_chain_multiret_repeat(){
	h = new Holder()
	sum = 0
	for i = 0; i < 1000; i += 1 {
		a, b = h.cur.two(i)
		sum += b - a
		c, d = h.arr[0].who()
		sum += d - c
	}
	if sum != 1000 + 8000 os.dief("loop sum: %d", sum)

	// Recursion through a chained receiver.
	p = new Pair(5)
	p.next = p
	n, t = p.next.depth(10)
	if n != 10 || t != 5 os.dief("recursion depth: %d %d", n, t)

	// Closure body owns its own hidden receiver slot.
	f = func(){
		a, b = h.cur.who()
		return b
	}
	if f() != 14 os.die("closure chain who != 14")

	if g_chain_one != 11 os.dief("package init one: %d", g_chain_one)
	if g_chain_first != 12 os.dief("package init first: %d", g_chain_first)

	d = new ChainDefaults()
	if d.one != 31 || d.first != 32 || d.sum != 67
		os.dief("member defaults: %d %d %d", d.one, d.first, d.sum)
	dc = new ChainDefaultsChild()
	if dc.extra != 35 || dc.one != 31 || dc.sum != 67
		os.dief("child member defaults: %d %d %d", dc.extra, dc.one, dc.sum)
	fmt.println("test chain multiret repeat success")
}

func main(){
	test_chain_member()
	test_chain_arr()
	test_complex()
	test_chain_multiret_receivers()
	test_chain_multiret_contexts()
	test_chain_multiret_repeat()
}