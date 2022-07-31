use fmt
use os


class Grand {
	func grand_child(){
		fmt.println("test grand_child")
		if this.who() != "child" 
			os.die("this should be child")
		fmt.println("test grand_child success")
	}
}
Grand::teach(){
	fmt.println("test grand teach child")
	if this.dynamic_var != 100 {
		os.die("child.dynmic_var should be 99")
	}
	fmt.println("test grand teach child success")
}
class Father : Grand {
	func father_child(){
		fmt.println("test father_child")
		if this.who() != "child" 
			os.die("this should be child")
		fmt.println("test father_child success")
	}
}
class Child  : Father {
	func child(){
		fmt.println("test child")
		if this.who() != "child" 
			os.die("this should be child")
		fmt.println("test child success")
	}
}
Grand::who(){ return "grand" }
Father::who(){ return "father" }
Child::who() { return "child" }

func test_inerit(obj){
	obj.child()
	obj.father_child()
	obj.grand_child()
}

func test_access_child(obj){
	obj.dynamic_var = 100
	obj.teach()
}
func main(){
	obj = new Child()
	test_inerit(obj)
	test_access_child(obj)
}
