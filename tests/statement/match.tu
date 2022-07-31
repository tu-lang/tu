
use fmt

func test_int(){
	var = 10
	match var {
		11 : os.die("not 11")
		10 : {
			fmt.println("right")
		}
	}
	match 10 {
		13 : {
			os.die("not 13")
		}
		var : fmt.println("right")
	}
	match var {
		5 + 5 : fmt.println("right")
		15    :{
			fmt.println("not right")
			os.exit(-1)
		}
	}
	match var {
		100 + 200 : os.die("not 200")
		300 : os.die("not 300")
		_   : fmt.println("right")
	}
	fmt.println("[match] test int success")
}
func test_string(){
	var = "str"
	match var {
		"str1" : os.die("not str1")
		"str"   : fmt.println("right")
		_ : os.die("not default")
	}
	fmt.println("[match] test string success")
}
func test_kv(){
	arr = [1,3,4,5]
	match arr[1] {
		1 : os.die("not 1")
		4 : os.die("not 4")
		3 : fmt.println("yes")
		_ : os.die("not default")
	}
	match 5 {
		arr[0] : os.die("not 1")
		arr[1] : os.die("not 3")
		arr[2] : os.die("not 4")
		arr[3] : fmt.println("right")
		_ : os.die("not default")
	}
	fmt.println("[match] test kv success")
}
func test_no_brace(){
	f  = func(){
		var = 100
		match var {
			200 : return 200
			100 : return 100
		}
		return 300
	}
	if f() != 100 {
		os.die("should be 100")
	}
	fmt.println("test no brace success")
}
func main(){
	test_int()
	test_string()
	test_kv()
	test_no_brace()
}
