use fmt
use os


class Grand {
	grand = "grand"
}
class Father : Grand {
	father = "father"
	func init(){
		super.init()
	}
	func get(){ return "father"}
}
class Child  : Father {
	child = "child"
	func init(){
		super.init()
	}
	func get(){return "child"}
	func testsuper(){
		if super.get() != "father" os.panic("super.get != father")
		if this.get() != "child"  os.panic("this.get != child")
		fmt.println("testsuper success")
	}
}
func main(){
	obj = new Child()
	obj.testsuper()
	if obj.grand != "grand" os.panic("obj.grand != grand")
	if obj.father != "father" os.panic("obj.father != father")
	if obj.child != "child" os.panic("obj.child != child")
	fmt.println("test inherit super success")
}
