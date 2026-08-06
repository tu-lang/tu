// Static fn: try/catch/finally/defer across statement contexts.

use fmt
use os
use exception

g_tag = ""

fn test_no_throw(){
	fmt.println("test_no_throw")
	hit = 0
	try {
		hit = 1
	} catch (e) {
		hit = 2
	}
	if hit != 1 {
		os.die("no_throw want hit=1")
	}
	fmt.println("test_no_throw passed")
}

fn test_return_from_try(){
	fmt.println("test_return_from_try")
	r = pick_in_try()
	if r != 7 {
		os.die("return from try want 7")
	}
	fmt.println("test_return_from_try passed")
}

fn pick_in_try(){
	try {
		return 7
	} catch (e) {
		return 0
	}
	return 1
}

// return through try must still run finally (PHP/Go alignment).
fn test_return_runs_finally(){
	fmt.println("test_return_runs_finally")
	g_tag = ""
	r = pick_with_finally()
	if r != 9 {
		os.die("return+finally want 9")
	}
	if g_tag != "F" {
		os.die("return+finally want F got " + g_tag)
	}
	fmt.println("test_return_runs_finally passed")
}

fn pick_with_finally(){
	try {
		return 9
	} catch (e) {
		return 0
	} finally {
		g_tag += "F"
	}
	return 1
}

fn test_return_nested_finally(){
	fmt.println("test_return_nested_finally")
	g_tag = ""
	r = pick_nested_finally()
	if r != 3 {
		os.die("nested return+finally want 3")
	}
	if g_tag != "IO" {
		os.die("nested finally want IO got " + g_tag)
	}
	fmt.println("test_return_nested_finally passed")
}

fn pick_nested_finally(){
	try {
		try {
			return 3
		} finally {
			g_tag += "I"
		}
	} finally {
		g_tag += "O"
	}
	return 0
}

// Defer mutates stack local via out-pointer observed by caller.
fn bump_local_via_defer(p<i32*>){
	defer {
		*p = *p + 1
	}
	defer {
		*p = *p + 1
	}
}

fn test_defer_local(){
	fmt.println("test_defer_local")
	n<i32> = 0
	bump_local_via_defer(&n)
	if n != 2 {
		os.die("defer local want 2")
	}
	fmt.println("test_defer_local passed")
}

fn test_throw_in_if(){
	fmt.println("test_throw_in_if")
	hit = 0
	try {
		if true {
			throw new exception.Exception("ifthrow")
		}
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("throw in if")
	}
	fmt.println("test_throw_in_if passed")
}

fn test_throw_in_while(){
	fmt.println("test_throw_in_while")
	hit = 0
	i = 0
	try {
		while i < 3 {
			i = i + 1
			if i == 2 {
				throw new exception.Exception("wh")
			}
		}
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("throw in while")
	}
	fmt.println("test_throw_in_while passed")
}

fn test_throw_in_for(){
	fmt.println("test_throw_in_for")
	hit = 0
	try {
		for j = 0; j < 4; j = j + 1 {
			if j == 2 {
				throw new exception.Exception("for")
			}
		}
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("throw in for")
	}
	fmt.println("test_throw_in_for passed")
}

fn test_nested_inner_catch(){
	fmt.println("test_nested_inner_catch")
	hit = 0
	try {
		try {
			throw new exception.Exception("nested")
		} catch (e) {
			hit = 1
		}
	} catch (e2) {
		hit = 2
	}
	if hit != 1 {
		os.die("nested inner catch")
	}
	fmt.println("test_nested_inner_catch passed")
}

fn test_finally_on_normal_path(){
	fmt.println("test_finally_on_normal_path")
	fin = 0
	try {
		fin = 0
	} catch (e) {
	} finally {
		fin = 1
	}
	if fin != 1 {
		os.die("finally on normal path")
	}
	fmt.println("test_finally_on_normal_path passed")
}

fn test_defer_on_return(){
	fmt.println("test_defer_on_return")
	g_tag = ""
	early_ret_defer()
	if g_tag != "DA" {
		os.die("defer on return want DA got " + g_tag)
	}
	fmt.println("test_defer_on_return passed")
}

fn early_ret_defer(){
	defer {
		g_tag += "A"
	}
	defer {
		g_tag += "D"
	}
	return
}

fn test_match_in_try(){
	fmt.println("test_match_in_try")
	hit = 0
	try {
		match 2 {
			1 : os.die("match arm 1")
			2 : throw new exception.Exception("match")
			_ : os.die("match default")
		}
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("match in try")
	}
	fmt.println("test_match_in_try passed")
}

fn test_assign_after_catch(){
	fmt.println("test_assign_after_catch")
	v = 0
	try {
		throw new exception.Exception("c")
	} catch (e) {
		v = 10
	}
	v = v + 5
	if v != 15 {
		os.die("assign after catch want 15")
	}
	fmt.println("test_assign_after_catch passed")
}

fn test_try_only_finally(){
	fmt.println("test_try_only_finally")
	fin = 0
	try {
		fin = 2
	} finally {
		fin = fin + 1
	}
	if fin != 3 {
		os.die("try only finally want 3")
	}
	fmt.println("test_try_only_finally passed")
}

class StmtErr : exception.Exception {
	func init(msg){
		super.init(msg)
	}
}

fn test_typed_catch_mismatch(){
	fmt.println("test_typed_catch_mismatch")
	wrong = 0
	outer = 0
	try {
		try {
			throw new exception.Exception("base")
		} catch (StmtErr e) {
			wrong = 1
		}
	} catch (e) {
		outer = 1
	}
	if wrong != 0 {
		os.die("typed catch should miss base Exception")
	}
	if outer != 1 {
		os.die("outer catch miss")
	}
	fmt.println("test_typed_catch_mismatch passed")
}

fn test_finally_defer_catch_order(){
	fmt.println("test_finally_defer_catch_order")
	g_tag = ""
	stmt_fdc_inner()
	if g_tag != "FDC" {
		os.die("want FDC got " + g_tag)
	}
	fmt.println("test_finally_defer_catch_order passed")
}

fn stmt_fdc_inner(){
	defer {
		g_tag += "D"
	}
	try {
		throw new exception.Exception("o")
	} catch (e) {
		g_tag += "C"
	} finally {
		g_tag += "F"
	}
}

func main(){
	test_no_throw()
	test_return_from_try()
	test_return_runs_finally()
	test_return_nested_finally()
	test_defer_local()
	test_throw_in_if()
	test_throw_in_while()
	test_throw_in_for()
	test_nested_inner_catch()
	test_finally_on_normal_path()
	test_defer_on_return()
	test_match_in_try()
	test_assign_after_catch()
	test_try_only_finally()
	test_typed_catch_mismatch()
	test_finally_defer_catch_order()
	fmt.println("all statement exc tests passed")
}
