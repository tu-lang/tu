
use fmt
use runtime
use std

func test_array(){
	fmt.println("test array pop")
	arr = []
	fmt.assert(std.pop(arr),null,"init array pop should be null")

	for(i = 1 ; i <= 8 ; i += 1){
		arr[] = i
	}
	for(i = 8 ; i >= 1 ; i -= 1){
		fmt.assert(std.pop(arr),i,"array pop should be " + i)
	}
	fmt.assert(std.pop(arr),null,"array pop should be null")
	fmt.println("test array pop success")
}
func test_tail_head(){
	fmt.println("test tail_head")

	//test arr
	arr = []
	fmt.assert(std.tail(arr),null,"init array tail should be null")
	fmt.assert(std.head(arr),null,"init array head should be null")
	arr[] = 100
	fmt.assert(std.tail(arr),100,"init array tail should be 100")
	fmt.assert(std.head(arr),100,"init array head should be 100")
	//test map
	map = {}
	// fmt.assert(std.tail(map),null,"init map tail should be null")
	fmt.assert(std.head(map),null,"init map head should be null")
	map["test"] = "map"
	// fmt.assert(std.tail(map),"map","init map tail should be null")
	fmt.assert(std.head(map),"map","init map head should be null")

	fmt.println("test tail head success")
}

func main(){
	test_array()
	test_tail_head()
}
