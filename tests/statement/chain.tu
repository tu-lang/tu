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
	fn = func(){
		fn1 = func(){
			arr = ["all"]
			return arr
		}
		obj = new V()
		obj.p = fn1
		arr = [obj]
		return arr
	}
	a = fn()[0].p()[0]
	if a != "all" {
		fmt.println("func().[0].p()[0]")
		os.exit(-1)
	}
	fmt.println("func().[0].p()[0] test sucess",a)

}

func main(){
    call()
    call_arr()
	arr_arr()
	call_var()
	all()
}