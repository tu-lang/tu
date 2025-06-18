use fmt
use os
use std
use runtime

// func manual(size,v1,v2,v3,v4,v5,v6,v7,v8){
func manual(_args...)
{
	args<u64*> = _args
	size<u32> = *args
	args += 8
	if size != 8 os.die("test manual.size failed")
	v1 = args[0]
	if v1 != 1  os.die("test mainl.v1 failed")
	v2 = args[1]
	if v2 != 2  os.die("test mainl.v2 failed")
	v3 = args[2]
	if v3 != 3  os.die("test mainl.v3 failed")
	v4 = args[3]
	if v4 != 4  os.die("test mainl.v4 failed")
	v5 = args[4]
	if v5 != 5  os.die("test mainl.v5 failed")
	v6 = args[5]
	if v6 != 6  os.die("test mainl.v6 failed")
	v7 = args[6]
	if v7 != 7  os.die("test mainl.v7 failed")
	v8 = args[7]
	if v8 != 8  os.die("test mainl.v8 failed")
	fmt.println("test manual success")
	return 100
}
func auto(_args...){
	args<u64*> = _args
	count = *args
	args += 8 // skip count
	var<runtime.Value> = null
    for (i<i32> = 0 ; i < count ; i += 1){
		v = args[i]
		k = int(i)
		if (k + 1 ) != v os.die("test manual failed")
	}
	fmt.println("test auto success")
	return 200
}
func f2(_args...){
	args<u64*> = _args
	size<u32> = args[0]
	if size != 8 os.die("f2 test failed")
	ret1 = manual(_args) // 100
	ret2 = auto(_args) // 200

	fmt.println("test f2 success")
	return ret1 + ret2
}
func f1(_args...){
	args<u64*> = _args
	size<u32> = args[0]
	if size != 8 os.die("f1 test failed")
	ret = f2(_args)
	var = ret + 1	
	fmt.println("test f1 success")
	return var
}
func test_wrap(){
	ret = f1(1,2,3,4,5,6,7,8)
	if ret != 301 os.die("ret should be 301")

	fmt.println("test varidic params success")
}

func native(_args...){
	args<u64*> = _args
	var = null
	args += 8
    for (i<i32> = 0 ; i < 8 ; i += 1){
		var = args[i]	
		var = *var
		if (i + 1) != var os.die("test native failed")
	}
	fmt.println("test native success")
	return "test"
}
// extern _ main_native()
func f11(_args...){
	args<u64*> = _args
	size<u32> = args[0]
	if size != 8 os.die("native f1 test failed")
	ret = native(_args)
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