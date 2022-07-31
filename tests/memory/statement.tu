
use fmt
use runtime
use os

func test_map(){
	fmt.println("range for: test map")
	map = {"a":"b","c":"d"}
	for(k,v : map){
		fmt.println("[%s]:%s\n",k,v)
	}
	fmt.println("range for: test map success")
	return map
}
func test_range_for(){
	fmt.println("range for: test array")
	map = test_map()
	arr = ["1",map,2,"sdfdsf","3"]
	for(i,v : arr){
		if   runtime.is_map(v)  {
			for(k,v2 : v){
				fmt.print("\t",k,"-",v2,"\n")
			}
			break
		}else{
			fmt.print(i,"-",v,"\n")
		}
	}
	fmt.println("range for: test array success")
}

func test_while(){
	a<i8> = 10
	b<i8> = 9

	while a != b {
		fmt.println(int(a),int(b))
		b += 1
	}
}
mem T1 {
	i8 a
	i32 b
}
func test_new(){
	fmt.println("test new expression")
	// 1. new struct
	a<T1> = new T1
	a.b = 1000
	if  a.b != 1000 {
		fmt.println("test new mem failed")
		os.exit(-1)
	}
	// 2. new var(var must be memory type)
	b<i8> = 8
	bp<i32*> = new b
	*bp = 10000
	if  *bp != 10000 {
		fmt.println("test new var failed")
		os.exit(-1)
	}

	// 3. new num
	c<i32*> = new 8
	*c = 10000
	if  *c != 10000 {
		fmt.println("test new 8 failed")
		os.exit(-1)
	}
	fmt.println("test new expression end")
}
func main(){
	test_range_for()
	test_while()
	test_new()
}