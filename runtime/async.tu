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
    printf(*"Future already Done!:\n")
	infos = debug.stack(5.(i8))
    i = 1
    for v : infos {
        printf(*"%d: %s\n",i,v)
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

// internal call
// @return Future
fn dynfuturenew(obj<Value> , callid<u64>, args<i64*>...) {
    fh<VObjFunc> = object_func_addr2(callid,obj)    
    if fh.asyncsize < fh.argsize * 8 {
        dief(*"future stack size wrong %d:%d\n",fh.asyncsize,fh.argsize*8)
    }
    //alloc stack
    fut<Future> = new fh.asyncsize
    fut.virf = fh.entry

    //copy args
    paramscount<i32> = fh.argsize
    argscount<i32>   = args[0]
    argstack<i64*>   = args + ptrSize
    futpstack<i64*>  = fut + ptrSize
    for i<i32> = 0 ; i < paramscount ; i += 1 {
        //miss
        if i + 1 > argscount {
            futpstack[i] = &internal_null
        }else{
            futpstack[i] = argstack[i]
        }
    }
    return fut
}

