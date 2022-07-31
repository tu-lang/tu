
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


func main(){
	test_array()
}
