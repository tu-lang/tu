use fmt
use os

func call(){
	ca =  func(){
		return func(){
			return 100
		}
	}
	re = ca()()
	if re != 100 {
	    fmt.println("call()() test failed")
		os.exit(-1)
	}
	fmt.println("test call success!",re)
}
func call_arr(){
	ca =  func(){
	    arr = ["first","second","third"]
	    return arr
	}
	re = ca()[0]
	if re != "first" {
	    fmt.println("call()[0] test failed")
		os.exit(-1)
	}
	fmt.println("test call arr success!",re)
}
func arr_arr(){
	ca =  func(){
		arr1    = ["arr1","arr1"]
	    arr2 = ["arr2",arr1]
	    return arr2
	}
	re = ca()[1][0]
	if re != "arr1" {
	    fmt.println("arr[1][1] test failed")
		os.exit(-1)
	}
	fmt.println("test arr[][] success!",re)
}
class V
{
	var
}
func call_var(){
	ca =  func(){
		obj = new V() 
		obj.var = "obj"
		return obj
	}
	re = ca().var
	if re != "obj" {
	    fmt.println("func().objmemeber test failed")
		os.exit(-1)
	}
	fmt.println("test func().obj success!",re)

}
func all(){
	fc = func(){
		fn1 = func(){
			arr = ["all"]
			return arr
		}
		obj = new V()
		obj.p = fn1
		arr = [obj]
		return arr
	}
	a = fc()[0].p()[0]
	if a != "all" {
		fmt.println("func().[0].p()[0]")
		os.exit(-1)
	}
	fmt.println("func().[0].p()[0] test sucess",a)

}

// Call-suffix helpers: closures returned through calls, arrays and maps.
func cs_mk(n){ return func(){ return n } }
func cs_mk2(n){
	return func(){
		k = n
		return func(){ return k * 2 }
	}
}
func cs_mkobj(n){
	return func(){
		o = new V()
		o.var = n
		return o
	}
}
func cs_mkarr(){ return func(){ return [10, 20, 30] } }
func cs_two(){ return func(){ return 1, 2 } }
func cs_plus(a, b){ return a + b }
func cs_ret(arr){ return arr[0]() + 1 }

// A trailing () after an index / call / member must not leak a stack slot.
func test_call_suffix_tail(){
	arr = [cs_mk(9), cs_mk(1), cs_two()]
	m = {"f": cs_mk(3)}
	if cs_mk(3)() != 3 { fmt.println("mk(3)() failed") os.exit(-1) }
	if arr[0]() + 1 != 10 { fmt.println("arr[0]() + 1 failed") os.exit(-1) }
	if m["f"]() * 2 != 6 { fmt.println("m[f]() * 2 failed") os.exit(-1) }
	if arr[0]() != 9 && m["f"]() == 3 { fmt.println("arr[0]() && failed") os.exit(-1) }
	if cs_plus(arr[0](), m["f"]()) != 12 { fmt.println("call arg failed") os.exit(-1) }
	if cs_ret(arr) != 10 { fmt.println("return arr[0]() failed") os.exit(-1) }
	a, b = arr[2]()
	if a != 1 || b != 2 { fmt.println("multi return arr[2]() failed") os.exit(-1) }
	fmt.println("test call suffix tail success")
}

// A () in the middle of a chain must feed its result to the next hop.
func test_call_suffix_mid(){
	if cs_mk2(3)()() != 6 { fmt.println("mk2(3)()() failed") os.exit(-1) }
	if cs_mkobj(4)().var + 1 != 5 { fmt.println("mkobj(4)().var failed") os.exit(-1) }
	if cs_mkarr()()[1] != 20 { fmt.println("mkarr()()[1] failed") os.exit(-1) }
	fs = [cs_mk2(5)]
	if fs[0]()() != 10 { fmt.println("fs[0]()() failed") os.exit(-1) }
	m = {"g": cs_mkarr()}
	if m["g"]()[2] != 30 { fmt.println("m[g]()[2] failed") os.exit(-1) }
	fmt.println("test call suffix mid success")
}

// Stack stays balanced across many iterations of call suffixes.
func test_call_suffix_loop(){
	arr = [cs_mk(9), cs_mk(1)]
	s = 0
	for i = 0; i < 1000; i += 1 {
		s += arr[0]() + arr[1]()
		s += cs_mk2(1)()() - 2
	}
	if s != 10000 { fmt.println("call suffix loop failed", s) os.exit(-1) }
	fmt.println("test call suffix loop success", s)
}

func main(){
    call()
    call_arr()
	arr_arr()
	call_var()
	all()
	test_call_suffix_tail()
	test_call_suffix_mid()
	test_call_suffix_loop()
}