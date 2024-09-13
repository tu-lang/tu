PollError<i64>   = 0
PollReady<i64>   = 1
PollPending<i64> = 2

mem Future {
    VObjFunc* virf
    //....
}
Future::poll(){
    dief(*"call runtime future poll")
}

fn get_future_poll(fut<Future>){
    if fut == null dief(*"future execute on null")
    if fut.virf == null dief(*"future vir table is null")
    return fut.virf
}

fn futuredone(){
    fmt.vfprintf(std.STDOUT,*"Future already Done!:\n")
	infos = debug.stack(5.(i8))
    i = 1
    for v : infos {
        fmt.printf("%d: %s\n",i,v)
        i += 1
    }
	std.die(-1.(i8))
}

fn block(p<Future>){
    if p == null {
        dief(*"[run] future is null")
    }
    spincnt<i32> = 10
    loop {
        ready<i32>, result<i64> = p.poll()
        if ready == PollReady {
            return result
        }
        park()
        procyield(spincnt)
    }
}
