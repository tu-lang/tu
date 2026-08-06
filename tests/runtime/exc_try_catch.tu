// Exception / defer / finally integration tests (L2b + L2c).

use fmt
use os
use std
use exception
use runtime.debug

class MyErr : exception.Exception {
	func init(msg){
		super.init(msg)
	}
}

g_finally = 0
g_defer = 0
g_order = ""

fn test_catch_basic(){
	fmt.println("test_catch_basic")
	hit = 0
	try {
		throw new exception.Exception("boom")
	} catch (e) {
		hit = 1
		if e.getMessage() != "boom" {
			os.die("bad message")
		}
	}
	if hit != 1 {
		os.die("catch not hit")
	}
	fmt.println("test_catch_basic passed")
}

fn test_finally_runs(){
	fmt.println("test_finally_runs")
	g_finally = 0
	try {
		throw new exception.Exception("x")
	} catch (e) {
	} finally {
		g_finally = 1
	}
	if g_finally != 1 {
		os.die("finally not run")
	}
	fmt.println("test_finally_runs passed")
}

fn test_finally_before_catch(){
	fmt.println("test_finally_before_catch")
	g_order = ""
	try {
		throw new exception.Exception("o")
	} catch (e) {
		g_order += "C"
	} finally {
		g_order += "F"
	}
	if g_order != "FC" {
		os.die("order want FC got " + g_order)
	}
	fmt.println("test_finally_before_catch passed")
}

fn test_defer_lifo(){
	fmt.println("test_defer_lifo")
	g_order = ""
	test_defer_inner()
	if g_order != "BA" {
		os.die("defer order want BA got " + g_order)
	}
	fmt.println("test_defer_lifo passed")
}

fn test_defer_inner(){
	defer {
		g_order += "A"
	}
	defer {
		g_order += "B"
	}
}

fn test_inherit_catch(){
	fmt.println("test_inherit_catch")
	hit = 0
	try {
		throw new MyErr("mine")
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("inherit catch miss")
	}
	fmt.println("test_inherit_catch passed")
}

fn test_bubble(){
	fmt.println("test_bubble")
	hit = 0
	try {
		test_bubble_inner()
	} catch (e) {
		hit = 1
		if e.getMessage() != "up" {
			os.die("bubble msg")
		}
	}
	if hit != 1 {
		os.die("bubble miss")
	}
	fmt.println("test_bubble passed")
}

fn test_bubble_inner(){
	throw new exception.Exception("up")
}

fn test_trace(){
	fmt.println("test_trace")
	try {
		throw new exception.Exception("t")
	} catch (e) {
		tr = e.getTrace()
		if std.len(tr) < 1 {
			os.die("empty trace")
		}
	}
	fmt.println("test_trace passed")
}

fn test_caller_api(){
	fmt.println("test_caller_api")
	s = debug.Caller(0)
	if s == "" {
		os.die("Caller empty")
	}
	fmt.println("test_caller_api passed")
}

fn test_defer_with_try(){
	fmt.println("test_defer_with_try")
	g_order = ""
	test_defer_try_inner()
	if g_order != "FD" {
		os.die("defer+try want FD got " + g_order)
	}
	fmt.println("test_defer_with_try passed")
}

fn test_defer_try_inner(){
	defer {
		g_order += "D"
	}
	try {
		throw new exception.Exception("x")
	} catch (e) {
	} finally {
		g_order += "F"
	}
}

fn test_previous(){
	fmt.println("test_previous")
	hit = 0
	try {
		try {
			throw new exception.Exception("inner")
		} finally {
			throw new exception.Exception("outer")
		}
	} catch (e) {
		hit = 1
		if e.getMessage() != "outer" {
			os.die("want outer msg")
		}
		p = e.getPrevious()
		if p == null {
			os.die("missing previous")
		}
		if p.getMessage() != "inner" {
			os.die("want inner previous")
		}
	}
	if hit != 1 {
		os.die("previous catch miss")
	}
	fmt.println("test_previous passed")
}

fn test_rethrow_bubble(){
	fmt.println("test_rethrow_bubble")
	hit = 0
	try {
		try {
			throw new exception.Exception("r")
		} catch (e) {
			throw e
		}
	} catch (e2) {
		hit = 1
		if e2.getMessage() != "r" {
			os.die("rethrow msg")
		}
	}
	if hit != 1 {
		os.die("rethrow miss")
	}
	fmt.println("test_rethrow_bubble passed")
}

fn test_catch_type_mismatch(){
	fmt.println("test_catch_type_mismatch")
	hit_outer = 0
	hit_wrong = 0
	try {
		try {
			throw new exception.Exception("base")
		} catch (MyErr e) {
			hit_wrong = 1
		}
	} catch (e) {
		hit_outer = 1
	}
	if hit_wrong != 0 {
		os.die("wrong catch type matched")
	}
	if hit_outer != 1 {
		os.die("outer catch miss on type mismatch")
	}
	fmt.println("test_catch_type_mismatch passed")
}

fn test_catch_order_derived_first(){
	fmt.println("test_catch_order_derived_first")
	g_order = ""
	try {
		throw new MyErr("m")
	} catch (MyErr e) {
		g_order += "D"
	} catch (Exception e) {
		g_order += "B"
	}
	if g_order != "D" {
		os.die("want D only got " + g_order)
	}
	fmt.println("test_catch_order_derived_first passed")
}

fn test_catch_order_base_first(){
	fmt.println("test_catch_order_base_first")
	g_order = ""
	try {
		throw new MyErr("m")
	} catch (Exception e) {
		g_order += "B"
	} catch (MyErr e) {
		g_order += "D"
	}
	if g_order != "B" {
		os.die("want B only got " + g_order)
	}
	fmt.println("test_catch_order_base_first passed")
}

fn test_funcforpc(){
	fmt.println("test_funcforpc")
	debug.debug_init()
	pc<u64> = test_funcforpc.(u64)
	r = debug.FuncForPC(pc)
	if r == null {
		os.die("FuncForPC miss")
	}
	name = debug.funcname(r)
	if name == "??" || name == "" {
		os.die("FuncForPC name empty")
	}
	fmt.println("test_funcforpc passed")
}

fn main(){
	test_catch_basic()
	test_finally_runs()
	test_finally_before_catch()
	test_defer_lifo()
	test_inherit_catch()
	test_bubble()
	test_trace()
	test_caller_api()
	test_defer_with_try()
	test_previous()
	test_rethrow_bubble()
	test_catch_type_mismatch()
	test_catch_order_derived_first()
	test_catch_order_base_first()
	test_funcforpc()
	fmt.println("all exception tests passed")
}
