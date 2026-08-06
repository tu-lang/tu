// Static mem: try/catch/finally/defer/throw in mem methods (pure static track).
// Defer bodies use package globals (defer thunk cannot capture this/locals yet).

use fmt
use os
use exception

g_order = ""
g_hit = 0

mem Sink {
	i32 tag
}

Sink::reset(){
	this.tag = 0
}

Sink::get() i32 {
	return this.tag
}

Sink::set(v<i32>){
	this.tag = v
}

// Throw from mem method; caller catches.
Sink::boom(){
	throw new exception.Exception("mem boom")
}

Sink::catchInside(){
	hit = 0
	try {
		this.boom()
	} catch (e) {
		hit = 1
		if e.getMessage() != "mem boom" {
			os.die("mem catchInside msg")
		}
	}
	if hit != 1 {
		os.die("mem catchInside miss")
	}
}

Sink::noThrow(){
	this.tag = 0
	try {
		this.tag = 1
	} catch (e) {
		this.tag = 2
	}
	if this.tag != 1 {
		os.die("mem noThrow want tag=1")
	}
}

Sink::throwInIf(){
	hit = 0
	try {
		if true {
			throw new exception.Exception("mem if")
		}
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("mem throw in if")
	}
}

Sink::throwInWhile(){
	hit = 0
	i = 0
	try {
		while i < 3 {
			i = i + 1
			if i == 2 {
				throw new exception.Exception("mem while")
			}
		}
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("mem throw in while")
	}
}

Sink::throwInFor(){
	hit = 0
	try {
		for j = 0; j < 4; j = j + 1 {
			if j == 2 {
				throw new exception.Exception("mem for")
			}
		}
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("mem throw in for")
	}
}

Sink::nestedInnerCatch(){
	hit = 0
	try {
		try {
			throw new exception.Exception("mem nested")
		} catch (e) {
			hit = 1
		}
	} catch (e2) {
		hit = 2
	}
	if hit != 1 {
		os.die("mem nested inner catch")
	}
}

Sink::finallyNormal(){
	fin = 0
	try {
		fin = 0
	} catch (e) {
	} finally {
		fin = 1
	}
	if fin != 1 {
		os.die("mem finally normal path")
	}
}

Sink::finallyBeforeCatch(){
	g_order = ""
	try {
		throw new exception.Exception("mem o")
	} catch (e) {
		g_order += "C"
	} finally {
		g_order += "F"
	}
	if g_order != "FC" {
		os.die("mem finally before catch want FC got " + g_order)
	}
}

Sink::tryOnlyFinally(){
	fin = 0
	try {
		fin = 2
	} finally {
		fin = fin + 1
	}
	if fin != 3 {
		os.die("mem try only finally want 3")
	}
}

Sink::deferLifo(){
	g_order = ""
	this.deferInner()
	if g_order != "BA" {
		os.die("mem defer LIFO want BA got " + g_order)
	}
}

Sink::deferInner(){
	defer {
		g_order += "A"
	}
	defer {
		g_order += "B"
	}
}

Sink::deferOnReturn(){
	g_order = ""
	this.earlyRetDefer()
	if g_order != "DA" {
		os.die("mem defer on return want DA got " + g_order)
	}
}

Sink::earlyRetDefer(){
	defer {
		g_order += "A"
	}
	defer {
		g_order += "D"
	}
	return
}

Sink::matchInTry(){
	hit = 0
	try {
		match 2 {
			1 : os.die("mem match arm 1")
			2 : throw new exception.Exception("mem match")
			_ : os.die("mem match default")
		}
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("mem match in try")
	}
}

Sink::assignAfterCatch(){
	v = 0
	try {
		throw new exception.Exception("mem c")
	} catch (e) {
		v = 10
	}
	v = v + 5
	if v != 15 {
		os.die("mem assign after catch want 15")
	}
}

Sink::returnFromTry() i32 {
	try {
		return 7
	} catch (e) {
		return 0
	}
	return 1
}

Sink::setViaCatch(){
	this.tag = 0
	try {
		throw new exception.Exception("set")
	} catch (e) {
		this.tag = 9
	}
	if this.tag != 9 {
		os.die("mem set via catch")
	}
}

fn test_mem_boom_to_caller(){
	fmt.println("test_mem_boom_to_caller")
	s<Sink> = new Sink{}
	hit = 0
	try {
		s.boom()
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("mem boom to caller")
	}
	fmt.println("test_mem_boom_to_caller passed")
}

fn test_mem_catch_inside(){
	fmt.println("test_mem_catch_inside")
	s<Sink> = new Sink{}
	s.catchInside()
	fmt.println("test_mem_catch_inside passed")
}

fn test_mem_no_throw(){
	fmt.println("test_mem_no_throw")
	s<Sink> = new Sink{}
	s.noThrow()
	fmt.println("test_mem_no_throw passed")
}

fn test_mem_throw_in_if(){
	fmt.println("test_mem_throw_in_if")
	s<Sink> = new Sink{}
	s.throwInIf()
	fmt.println("test_mem_throw_in_if passed")
}

fn test_mem_throw_in_while(){
	fmt.println("test_mem_throw_in_while")
	s<Sink> = new Sink{}
	s.throwInWhile()
	fmt.println("test_mem_throw_in_while passed")
}

fn test_mem_throw_in_for(){
	fmt.println("test_mem_throw_in_for")
	s<Sink> = new Sink{}
	s.throwInFor()
	fmt.println("test_mem_throw_in_for passed")
}

fn test_mem_nested(){
	fmt.println("test_mem_nested")
	s<Sink> = new Sink{}
	s.nestedInnerCatch()
	fmt.println("test_mem_nested passed")
}

fn test_mem_finally_normal(){
	fmt.println("test_mem_finally_normal")
	s<Sink> = new Sink{}
	s.finallyNormal()
	fmt.println("test_mem_finally_normal passed")
}

fn test_mem_finally_before_catch(){
	fmt.println("test_mem_finally_before_catch")
	s<Sink> = new Sink{}
	s.finallyBeforeCatch()
	fmt.println("test_mem_finally_before_catch passed")
}

fn test_mem_try_only_finally(){
	fmt.println("test_mem_try_only_finally")
	s<Sink> = new Sink{}
	s.tryOnlyFinally()
	fmt.println("test_mem_try_only_finally passed")
}

fn test_mem_defer_lifo(){
	fmt.println("test_mem_defer_lifo")
	s<Sink> = new Sink{}
	s.deferLifo()
	fmt.println("test_mem_defer_lifo passed")
}

fn test_mem_defer_on_return(){
	fmt.println("test_mem_defer_on_return")
	s<Sink> = new Sink{}
	s.deferOnReturn()
	fmt.println("test_mem_defer_on_return passed")
}

fn test_mem_match_in_try(){
	fmt.println("test_mem_match_in_try")
	s<Sink> = new Sink{}
	s.matchInTry()
	fmt.println("test_mem_match_in_try passed")
}

fn test_mem_assign_after_catch(){
	fmt.println("test_mem_assign_after_catch")
	s<Sink> = new Sink{}
	s.assignAfterCatch()
	fmt.println("test_mem_assign_after_catch passed")
}

fn test_mem_return_from_try(){
	fmt.println("test_mem_return_from_try")
	s<Sink> = new Sink{}
	r<i32> = s.returnFromTry()
	if r != 7 {
		os.die("mem return from try want 7")
	}
	fmt.println("test_mem_return_from_try passed")
}

fn test_mem_set_via_catch(){
	fmt.println("test_mem_set_via_catch")
	s<Sink> = new Sink{}
	s.setViaCatch()
	if s.get() != 9 {
		os.die("mem get after catch")
	}
	fmt.println("test_mem_set_via_catch passed")
}

fn main(){
	test_mem_boom_to_caller()
	test_mem_catch_inside()
	test_mem_no_throw()
	test_mem_throw_in_if()
	test_mem_throw_in_while()
	test_mem_throw_in_for()
	test_mem_nested()
	test_mem_finally_normal()
	test_mem_finally_before_catch()
	test_mem_try_only_finally()
	test_mem_defer_lifo()
	test_mem_defer_on_return()
	test_mem_match_in_try()
	test_mem_assign_after_catch()
	test_mem_return_from_try()
	test_mem_set_via_catch()
	fmt.println("all memory exc tests passed")
}
