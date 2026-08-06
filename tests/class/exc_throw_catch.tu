// Dynamic class: try/catch/finally/defer/throw in member methods.

use fmt
use os
use exception

g_order = ""

class ErrA : exception.Exception {
	func init(msg){
		super.init(msg)
	}
}

class Worker {
	func throwUp(){
		throw new exception.Exception("from method")
	}

	func catchInside(){
		hit = 0
		try {
			this.throwUp()
		} catch (e) {
			hit = 1
			if e.getMessage() != "from method" {
				os.die("catchInside msg")
			}
		}
		if hit != 1 {
			os.die("catchInside miss")
		}
	}

	func deferInMethod(){
		g_order = ""
		this.deferInner()
		if g_order != "YX" {
			os.die("defer in method want YX got " + g_order)
		}
	}

	func deferInner(){
		defer {
			g_order += "X"
		}
		defer {
			g_order += "Y"
		}
	}

	func typedCatch(){
		msg = ""
		try {
			throw new ErrA("typed")
		} catch (ErrA e) {
			msg = e.getMessage()
		} catch (e) {
			msg = "wrong"
		}
		return msg
	}

	func finallyInMethod(){
		g_order = ""
		try {
			throw new exception.Exception("f")
		} catch (e) {
			g_order += "C"
		} finally {
			g_order += "F"
		}
	}

	func bubbleToCaller(){
		throw new exception.Exception("bubble")
	}
}

func test_method_throw_caught_by_caller(){
	fmt.println("test_method_throw_caught_by_caller")
	w = new Worker()
	hit = 0
	try {
		w.throwUp()
	} catch (e) {
		hit = 1
	}
	if hit != 1 {
		os.die("method throw to caller")
	}
	fmt.println("test_method_throw_caught_by_caller passed")
}

func test_method_catch_inside(){
	fmt.println("test_method_catch_inside")
	w = new Worker()
	w.catchInside()
	fmt.println("test_method_catch_inside passed")
}

func test_method_defer(){
	fmt.println("test_method_defer")
	w = new Worker()
	w.deferInMethod()
	fmt.println("test_method_defer passed")
}

func test_method_typed_catch(){
	fmt.println("test_method_typed_catch")
	w = new Worker()
	msg = w.typedCatch()
	if msg != "typed" {
		os.die("typed catch in method")
	}
	fmt.println("test_method_typed_catch passed")
}

func test_method_finally_order(){
	fmt.println("test_method_finally_order")
	w = new Worker()
	w.finallyInMethod()
	if g_order != "FC" {
		os.die("finally in method want FC got " + g_order)
	}
	fmt.println("test_method_finally_order passed")
}

func test_method_nested_on_object(){
	fmt.println("test_method_nested_on_object")
	w = new Worker()
	hit = 0
	try {
		try {
			w.bubbleToCaller()
		} catch (e) {
			hit = 1
		}
	} catch (e2) {
		hit = 2
	}
	if hit != 1 {
		os.die("nested on object")
	}
	fmt.println("test_method_nested_on_object passed")
}

func test_new_in_throw(){
	fmt.println("test_new_in_throw")
	hit = 0
	try {
		throw new ErrA("new throw")
	} catch (ErrA e) {
		hit = 1
	}
	if hit != 1 {
		os.die("new in throw catch")
	}
	fmt.println("test_new_in_throw passed")
}

func main(){
	test_method_throw_caught_by_caller()
	test_method_catch_inside()
	test_method_defer()
	test_method_typed_catch()
	test_method_finally_order()
	test_method_nested_on_object()
	test_new_in_throw()
	fmt.println("all class exc tests passed")
}
