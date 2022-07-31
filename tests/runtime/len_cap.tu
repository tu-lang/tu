
use fmt
use runtime

// 测试数组的长度和容量
func test_array(){
	fmt.println("test array len&cap")
	arr = []
	fmt.assert(runtime.len(arr),0,"init array len should be 0")
	fmt.assert(runtime.cap(arr),8,"init array cap should be 8")

	for(i = 1 ; i <= 8 ; i += 1){
		arr[] = i
		fmt.assert(runtime.len(arr),i,"init array len should be " + i)
		fmt.assert(runtime.cap(arr),8,"init array cap should be 8")
	}
	arr[] = 9
	fmt.assert(runtime.len(arr),9,"init array len should be 9")
	fmt.assert(runtime.cap(arr),16,"init array cap should be 16")
	fmt.println("test array len&cap success")
}


func main(){
	test_array()
}