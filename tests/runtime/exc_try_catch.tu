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
	if g_order != "FDC" {
		os.die("defer+try want FDC got " + g_order)
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
		g_order += "C"
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

fn test_throw_site_file_line(){
	fmt.println("test_throw_site_file_line")
	try {
		throw new exception.Exception("site")
	} catch (e) {
		f = e.getFile()
		ln = e.getLine()
		if f == "" {
			os.die("throw site file empty")
		}
		if ln <= 0 {
			os.die("throw site line <= 0")
		}
	}
	fmt.println("test_throw_site_file_line passed")
}

g_handler_hit = 0

fn uncaught_marker(obj<u64>){
	g_handler_hit = 1
	// Prove handler ran: exit 99 (default uncaught path exits 255 via dief).
	os.exit(99)
}

fn test_uncaught_handler(){
	fmt.println("test_uncaught_handler")
	pid<i64> = std.fork()
	if pid < 0 {
		os.die("fork failed")
	}
	if pid == 0 {
		exception.setExceptionHandler(uncaught_marker.(u64))
		throw new exception.Exception("uncaught")
		os.exit(1)
	}
	st<u64> = 0
	w<i32> = std.waitpid(pid.(i32), &st, 0)
	if w < 0 {
		os.die("waitpid failed")
	}
	sig<u64> = st & 0x7f.(u64)
	if sig != 0.(u64) {
		os.dief("uncaught child signalled sig=%d", sig.(i32))
	}
	exited<u64> = (st >> 8.(u64)) & 0xff.(u64)
	if exited != 99.(u64) {
		os.dief("uncaught handler want exit 99 got %d", exited.(i32))
	}
	fmt.println("test_uncaught_handler passed")
}

fn test_die_not_catchable(){
	fmt.println("test_die_not_catchable")
	pid<i64> = std.fork()
	if pid < 0 {
		os.die("fork failed")
	}
	if pid == 0 {
		try {
			os.die("fatal")
		} catch (e) {
			os.exit(42)
		}
		os.exit(43)
	}
	st<u64> = 0
	w<i32> = std.waitpid(pid.(i32), &st, 0)
	if w < 0 {
		os.die("waitpid failed")
	}
	sig<u64> = st & 0x7f.(u64)
	exited<u64> = (st >> 8.(u64)) & 0xff.(u64)
	if sig != 0.(u64) {
		os.dief("die child signalled sig=%d", sig.(i32))
	}
	if exited == 42.(u64) {
		os.die("os.die was caught by catch")
	}
	if exited == 0.(u64) {
		os.die("die child exited 0")
	}
	fmt.println("test_die_not_catchable passed")
}

fn nest_bomb(depth<i32>){
	if depth <= 0 {
		throw new exception.Exception("nest")
	}
	try {
		nest_bomb(depth - 1)
	} finally {
		throw new exception.Exception("nest")
	}
}

fn test_nest_depth_limit(){
	fmt.println("test_nest_depth_limit")
	pid<i64> = std.fork()
	if pid < 0 {
		os.die("fork failed")
	}
	if pid == 0 {
		try {
			nest_bomb(40)
		} catch (e) {
		}
		os.exit(0)
	}
	st<u64> = 0
	w<i32> = std.waitpid(pid.(i32), &st, 0)
	if w < 0 {
		os.die("waitpid failed")
	}
	sig<u64> = st & 0x7f.(u64)
	exited<u64> = (st >> 8.(u64)) & 0xff.(u64)
	if sig != 0.(u64) {
		os.dief("nest child signalled sig=%d", sig.(i32))
	}
	if exited == 0.(u64) {
		os.die("nest depth should have fatal-exited")
	}
	fmt.println("test_nest_depth_limit passed")
}

fn outer_defer_guard(){
	defer {
		g_order += "O"
	}
	inner_catch_defer()
}

fn inner_catch_defer(){
	defer {
		g_order += "I"
	}
	try {
		throw new exception.Exception("n")
	} catch (e) {
		g_order += "C"
	} finally {
		g_order += "F"
	}
	g_order += "D"
}

fn test_nested_fn_defer_not_stolen(){
	fmt.println("test_nested_fn_defer_not_stolen")
	g_order = ""
	outer_defer_guard()
	if g_order != "FICDO" {
		os.die("nested defer want FICDO got " + g_order)
	}
	fmt.println("test_nested_fn_defer_not_stolen passed")
}

fn test_throw_in_defer_previous(){
	fmt.println("test_throw_in_defer_previous")
	hit = 0
	try {
		try {
			defer {
				throw new exception.Exception("from-defer")
			}
			throw new exception.Exception("orig")
		} catch (e) {
			os.die("inner should not catch defer throw")
		}
	} catch (e) {
		hit = 1
		if e.getMessage() != "from-defer" {
			os.die("want from-defer msg")
		}
		p = e.getPrevious()
		if p == null {
			os.die("defer throw missing previous")
		}
		if p.getMessage() != "orig" {
			os.die("want orig previous")
		}
	}
	if hit != 1 {
		os.die("throw in defer miss")
	}
	fmt.println("test_throw_in_defer_previous passed")
}

fn test_multi_catch_only_first(){
	fmt.println("test_multi_catch_only_first")
	g_order = ""
	try {
		throw new exception.Exception("only")
	} catch (e) {
		g_order += "1"
	} catch (e2) {
		g_order += "2"
	}
	if g_order != "1" {
		os.die("multi catch want only first got " + g_order)
	}
	fmt.println("test_multi_catch_only_first passed")
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
	test_multi_catch_only_first()
	test_funcforpc()
	test_throw_site_file_line()
	test_uncaught_handler()
	test_die_not_catchable()
	test_nest_depth_limit()
	test_nested_fn_defer_not_stolen()
	test_throw_in_defer_previous()
	fmt.println("all exception tests passed")
}
