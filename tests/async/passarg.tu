use fmt
use runtime
use time
use std


ctx_queue<runtime.Future> = null
ctx_finish = false
fn schedule(){
	loop {
		time.sleep(1)
		fmt.println("loop")
		if ctx_queue != null break
	}
	fmt.println("wake future")
	ready<i32> = ctx_queue.poll(ctx_queue)
	if ready != runtime.PollReady {
		os.dief("wake failed")
	}
	ctx_finish = true

}

fn go(fut<runtime.Future>){
	state<i32>  = fut.poll(fut)
	if state != runtime.PollPending {
		os.die("should be pending state")
	}
}

mem Reader:async {
	i32 a
}
Reader::poll(ctx){
	if this.a == 100 {
		//sleep
		ctx_queue = ctx
		this.a = 10
		return runtime.PollPending
	}
	return runtime.PollReady,this.a
}
async case1(a,b,c){
	if a == 1 {} else os.dief("a != 1")
	if b == "2" {} else os.dief("b != 2")
	if c == '3' {} else os.dief("c != 3")
	fut<Reader> = new Reader{a : 100}
	fut.await

	if a == 1 {} else os.dief("a != 1")
	if b == "2" {} else os.dief("b != 2")
	if c == '3' {} else os.dief("c != 3")
}

fn test_wake(){
	fmt.println("test wake")

	runtime.newcore(schedule.(u64))
	go(case1(1,"2",'3'))
	time.sleep(2)
	if ctx_finish {} else {
		os.dief("not finish")
	}
	fmt.println("test wake success")
}

mem StopOnce: async {
	i32 stop
}
StopOnce::poll(ctx){
	if this.stop == 0 {
		this.stop = 1
		return runtime.PollPending
	}
	return runtime.PollReady
}

async tda(a,b,c,d,e,h,i){
	if a == true {} else os.die("a hould be true")
	if b == null {} else os.die("b should be null")
	if c == 'o' {} else  os.die("c != o")
	if d == 100  {} else os.die("d != 100")
	if e == 8.8 {} else os.die("e != 8.8")
	if h == "tda" {} else os.die("h != tda")
	if i[1] == "arr" {} else os.die("i[1] != arr")

	stopone<StopOnce> = new StopOnce{}
	stopone.await

	if a == true {} else os.die("a hould be true")
	if b == null {} else os.die("b should be null")
	if c == 'o' {} else  os.die("c != o")
	if d == 100  {} else os.die("d != 100")
	if e == 8.8 {} else os.die("e != 8.8")
	if h == "tda" {} else os.die("h != tda")
	if i[1] == "arr" {} else os.die("i[1] != arr")

	return h
}

fn test_pass_dynarg(){
	fmt.println("test dyn arg")
	ret = runtime.block(tda(
		true,null,'o',100,8.8,"tda",
		[ "null","arr"]
	))
	if ret == "tda" {} else os.die(
		"ret != tda"
	)
	fmt.println("test dyn arg success")
}

mem T1 {
	i32 a
}
async tsa(v1<i8>,v2<i8>,v3<f64>,v4<T1>){
	if v1 == 127 {} else os.die("v1 != 127")
	if v2 == -127 {} else os.die("v2 != 127")
	if v3 == 34.56 {} else os.die("v3 != 34.56")
	if v4 == null os.die("v4 == null")
	if v4.a == 100 {} else os.die("v4.a != 100")

	stopone<StopOnce> = new StopOnce{}
	stopone.await

	if v1 == 127 {} else os.die("v1 != 127")
	if v2 == -127 {} else os.die("v2 != 127")
	if v3 == 34.56 {} else os.die("v3 != 34.56")
	if v4 == null os.die("v4 == null")
	if v4.a == 100 {} else os.die("v4.a != 100")
	return "tsa"
}

fn test_pass_staticarg(){
	fmt.println("test pass static arg")
	fnumber<f64> = 34.56
	ret = runtime.block(tsa(
		127.(i8),129.(u8),fnumber,new T1{a: 100}
	))
	if ret == "tsa" {} else os.die(
		"ret != tsa"
	)
	fmt.println("test pass static arg success")
}

fn main(){
	test_wake()
	test_pass_dynarg()
	test_pass_staticarg()
}