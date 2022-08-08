use fmt
use os
use std
use runtime

func manual(size,v1,v2,v3,v4,v5,v6,v7,v8){
	if size != 8 os.die("test manual.size failed")
	if v1 != 1  os.die("test mainl.v1 failed")
	if v2 != 2  os.die("test mainl.v2 failed")
	if v3 != 3  os.die("test mainl.v3 failed")
	if v4 != 4  os.die("test mainl.v4 failed")
	if v5 != 5  os.die("test mainl.v5 failed")
	if v6 != 6  os.die("test mainl.v6 failed")
	if v7 != 7  os.die("test mainl.v7 failed")
	if v8 != 8  os.die("test mainl.v8 failed")
	fmt.println("test manual success")
	return 100
}
func auto(count,args...){
	var<runtime.Value> = null
	p<u64*> = &args
	stack<i32> = 5
	//TODO: should compiler do this stuff
    for (i = 1 ; i <= count ; i += 1){
		var = *p
		if stack < 1  p += 8
		else 		  p -= 8
		if stack == 1 {
			p = &args p += 32
		}		
		stack -= 1

		v = var
		if i != v os.die("test manual failed")
	}
	fmt.println("test auto success")
	return 200
}
func f2(size,args...){
	if size != 8 os.die("f2 test failed")
	ret1 = manual(args) // 100
	ret2 = auto(args) // 200

	fmt.println("test f2 success")
	return ret1 + ret2
}
func f1(size,args...){
	if size != 8 os.die("f1 test failed")
	ret = f2(args)
	var = ret + 1	
	fmt.println("test f1 success")
	return var
}
func test_wrap(){
	ret = f1(1,2,3,4,5,6,7,8)
	if ret != 301 os.die("ret should be 301")

	fmt.println("test varidic params success")
}

func native(args,_1,_2,_3,_4,_5){
// func native(args...){
	var<u64> = null
	p<u64*> = &args
	stack<i32> = 6
	//TODO: should compiler do this stuff
    for (i<i32> = 1 ; i <= 8 ; i += 1){
		var = *p
		if stack < 1  p += 8
		else 		  p -= 8
		if stack == 1 {
			p = &args p += 24
		}		
		stack -= 1
		if i != var os.die("test native failed")
	}
	fmt.println("test native success")
	return "test"
}
extern _ main_native()
func f11(size,args...){
	if size != 8 os.die("f1 test failed")
	ret = __.main_native(args)
	var = ret + "ok"	
	fmt.println("test f1 success")
	return var
}
func test_native(){
	ret = f11(1,2,3,4,5,6,7,8)
	if ret != "testok" os.die("ret should be testok")

	fmt.println("test varidic params success")
}
func main(){
	test_wrap()
	test_native()
}