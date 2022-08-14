
use fmt

garr = [3,5,7]
// use std
class NotI {
	int = 100
	str = "File.str"
	arr = [1,"arr",3,this.int]
	map = {"g": garr}
	func test(){
		fmt.println("test NotI ")
		if this.int != 100 
			os.panic("int should be 100 %d",this.int)
		if this.str != "File.str" 
			os.panic("File.str != %s",this.str)
		if this.arr[3] != 100 
			os.panic("100 != %d",this.arr[3])
		if this.map["g"][1] != 5 
			os.panic("5 != %d",this.map["g"][1])
		fmt.println("test NotI success")
	}
}
class WithI {
	int = 100
	str = "File.str"
	arr = [1,"arr",3,this.int]
	map = {"g": garr}
	func init(){
		this.int = 1 this.str = 1 this.arr = 1 this.map = 1
	}
	func test(){
		fmt.println("test WithI ")
		if this.int != 1 os.panic("int 1 != %d",this.int)
		if this.str != 1 os.panic("str 1 != %d",this.str)
		if this.map != 1 os.panic("map 1 != %d",this.map)
		if this.arr != 1 os.panic("arr 1 != %d",this.arr)
		fmt.println("test WithI success")
	}
}


func main(){
	obj = new NotI()
	obj.test()
	obj = new WithI()
	obj.test()
}


