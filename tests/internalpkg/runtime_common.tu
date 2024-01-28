use fmt
use runtime
use time
use std

lock<runtime.MutexInter:>
fn thread1(){
	println(*"test lock\n")
	lock.lock()
	println(*"test got lock 2\n")
	time.sleep(1)
	lock.unlock()
	println(*"test free lock\n")
}
fn println(arg1<i8*> , arg2<i8*> , arg3<i8*>){
	fmt.vfprintf(std.STDOUT,arg1,arg2,arg3)
}
fn test_lock(){
	lock.init()
	println(*"start test_lock\n")
	lock.lock()
	runtime.newcore(thread1)
	time.sleep(1)
	println(*"main prepare unlock\n")
	lock.unlock()
	time.sleep(1)
	lock.lock()
	println(*"test_lock success\n")
}
fn main(){
	test_lock()
}