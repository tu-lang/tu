use runtime 
use runtime.sys
use fmt
use std
func test_runtimemalloc()
{
	fmt.println("test runtime multi thread malloc start")
	maxsize<i32> = 100
	//测试分配的个数
	count<i32> = 10000000 //分配1千万次
	//用个数组存起来
	arr<i64*> = runtime.malloc(count * 8,0.(i8),1.(i8)) //每个元素为指针
	for(i<i64> = 0 ; i < count ; i += 1){
		size<i32> = std.srand(maxsize)//每次分配的内存随机大小
		if size == 0 || size < 8 {
			size = 8
		}
		newp<i64*> = runtime.malloc(size,0.(i8),1.(i8))
		*newp = i
		//保存起来
		arr[i] = newp
	}
	//验证
	for(i<i64> = 0 ; i < count ; i += 1){
		v<i64*> = arr[i]
		if *v == i {} else {
			os.dief("v:%d != i:%d",int(*v),int(i))
		}
	}
	fmt.println("test runtime multi thread malloc start end")


}
//std 内存分配器性能比较低，测试1万次分配
func test_stdmalloc(){
	maxsize<i32> = 100
	count<i32> = 10000
	//用个数组存起来
	arr<i64*> = std.malloc(count * 8,0.(i8),1.(i8)) //每个元素为指针
	for(i<i64> = 0 ; i < count ; i += 1){
		size<i32> = std.srand(maxsize)//每次分配的内存随机大小
		if size == 0 || size < 8 {
			size = 8
		}
		newp<i64*> = std.malloc(size,0.(i8),1.(i8))
		*newp = i
		//保存起来
		arr[i] = newp
	}
	//验证
	for(i<i64> = 0 ; i < count ; i += 1){
		v<i64*> = arr[i]
		if *v == i {} else {
			os.dief("v:%d != i:%d",int(*v),int(i))
		}
	}
	fmt.println("test std malloc start end")
}
func main(){
	test_runtimemalloc()
	test_stdmalloc()
}
