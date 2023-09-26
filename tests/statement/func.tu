use fmt
use pkg1
use os

func f2(){
	return "f2"
}
//test the varname is as same as package func name
func test_func_same(){
	test = pkg1.test()
	if test != "pkg1.test" {
		os.die("pkg1.test should return pkg1.test")
	}
	//FIXME: varname == funcname
	// f2 = f2()
	// if f2 != "f2" {
	// 	os.die("f2() should return f2()")
	// }

	fmt.println("test func same success")
}

//test block 
func block(){
	{
		a = 1
		if a == 1 {} else {
			os.die("a should eq 1")
		}
	}
}

func main(){
	test_func_same()
	block()
}