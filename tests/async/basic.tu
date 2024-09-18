use fmt
use runtime
use os

mem PollFuture {
    i32 ready
    i32 count
}
PollFuture::pending(){this.ready = 0}
PollFuture::poll(){
    this.count += 1
    if !this.ready {
        this.ready = 1 //ready
        return runtime.PollPending
    }
    return runtime.PollReady,this.count
}

async fn tc(){
    fut<PollFuture> = new PollFuture{}
    count<i32> = fut.await //block 1 count 2
    if count != 2 {
        os.dief("poll should be 2 times, now:%d",int(count))
    }
    count = fut.await     //block 0  count 1
    if count != 3 {
        os.dief("poll should be 3 times, now:%d",int(count))
    }
    // set block
    fut.pending()
    count<i32> = fut.await //block 1  count 2
    if count != 5 {
        os.dief("poll should be 5 times, now:%d",int(count))
    }
    return count
}
fn test_common(){
    fmt.println("test common start")
    v<runtime.Future> = tc()
    ready<i64>,ret = v.poll()
    if ready == runtime.PollPending {} else {
        os.die("future should be pending state")
    }
    if ret == null {} else {
        os.die("future ret should be 0")
    }
    ready,ret = v.poll()
    if ready == runtime.PollPending {} else {
        os.die("2 future should be pending state")
    }
    if ret == null {} else {
        os.die("2 future ret should be 0")
    }
    ready,ret1<i32> = v.poll()
    if ready == runtime.PollReady {} else {
        os.die("future should be Ready state")
    }
    if ret1 == 5 {} else {
        os.die("3 future ret should be 5")
    }
    fmt.println("test common success")
}


async fn tsi(){
    fut<PollFuture> = new PollFuture {
        ready: 0,
        count: 0,
    }
    //case1
    if fut.await == 2 {   // block 1 count 2
    }else {
        os.dief("future result should be 2")
    }
    //case2
    fut.pending() 
    if fut.await == 3 {   // block 1 count 4
        os.dief("future reuslt should be 4")
    }else if fut.await == 5 { // block 0 count 5
    }else{
        os.dief("future reuslt should be 5")
    }
    ret<i32> = fut.await   // block 0 count 6
    //case3
    if ret == 5 {
        os.die("future should be 6")
        fut.await
    }else {
        fut.pending()
        fut.await //block 1 count 8
    }
    //case4 
    if fut.await == 7 {     // block 0 count 9 
        os.die("future should be 9")
        fut.await 
    }else if fut.await == 10 { //block 0 count 10
        fut.pending()
        fut.await           // block 1 count 12
    }else{
        os.die("future should be 10")
        fut.await
    }
    //case5 
    if fut.await == 11 { //block 0 count 13
        os.die("future should be 13")
    }else if fut.await == 14 { //block 0 count 14
        fut.pending()
        if fut.await == 15 {  // block 1 count 16
            return fut.count
        }else if fut.await == 16 { // block 0 count 17
            if fut.await {
                return fut.count
            }
        }else {
            fut.pending()
            return fut.await //block 1 count 19
        }
    }
}

fn test_stmt_if(){
    fmt.println("test future statement - if")
    poller<runtime.Future> = tsi()
    //6 times
    for i = 0 ; i < 6 ; i += 1 {
        ready<i64> = poller.poll()
        if ready == runtime.PollPending {} else {
            os.dief("future:%d should be pending state",i)
        }
    }
    //last times,is ready
    ready<i64>,result<i32> = poller.poll()
    if ready != runtime.PollReady {
        os.dief("future state should be ready")
    }
    if result != 19 {
        os.die("future state result should be 19")
    }
    fmt.println("test future statement - success")
}
async fn tsw(){
    fut<PollFuture> = new PollFuture{}
    //case1
    fmt.println("case1 ",int(fut.count))
    count<i32> = 0
    while count != 2 {
        ret<i32> = fut.await //block 2 count 4
        fut.pending()
        count += 1
    }
    if fut.count != 4 {
        os.die("future return should be 4")
    }

    //case2
    fmt.println("case2 ",int(fut.count))
    while fut.await != 8 { //block 2 count 8
        fut.pending()
    }
    ret<i32> = fut.await   // block 0 count 9 
    if ret != 9 {
        os.die("future state should be 9")
    }

    fut.pending()
    //case3
    fmt.println("case3 ",int(fut.count))
    while fut.await > 0 { //block 1 count 11
        break
    }
    fut.pending()
    //case4
    fmt.println("case4 ",int(fut.count))
    loop {
        if fut.await == 13 { //block 1 count 13
            continue
        }
        fut.await       // block 0 count 15
        break
    }
    if fut.await != 16 { //block 0 count 16
        os.die("fut.await should be 16")
    }
    //case5
    fmt.println("case5 ",int(fut.count))
    lcount<i32> = 3
    fut.pending()
    itercount = 1  // 3
    while fut.await != 22 { // block 3  count 22
        fut.pending()
        itercount += 1
    }
    if itercount != 3 {
        os.dief("should iter 3 times:%d",itercount)
    }
    return fut.await // block 0 count 23

}

fn test_stmt_while(){
    fmt.println("test future statement - while")
    poller<runtime.Future> = tsw()

    //11 times
    for i = 0 ; i < 9 ; i += 1 {
        ready<i64> = poller.poll()
        if ready == runtime.PollPending {} else {
            os.dief("future:%d should be pending state",i)
        }
    }
    //last times,is ready
    ready<i64>,result<i32> = poller.poll()
    if ready != runtime.PollReady {
        os.dief("future state should be ready")
    }
    if result != 23 {
        os.die("future state result should be 22")
    }

    fmt.println("test future statement - while success")
}

async fn tstf(){
    fut<PollFuture> = new PollFuture{} 
    //case1
    fmt.println("case1",int(fut.count))
    for i = 0 ; i < 2 ; i += 1 {
        fut.await  //block 2 count 4
        fut.pending()
    }
    //case2
    fmt.println("case2",int(fut.count))
    for 
        i<i32> = fut.await ; // block 1 count 6
        fut.await < 10 ;     // block 0 count 10
        i += fut.await       // block 1 count 9
    {
        fut.pending()
    }
    fut.pending()             // count 10
    //case3
    fmt.println("case3",int(fut.count))
    for 
        i<i32> = fut.await   // block 1 count 12
        ; i < 100 ; i += 1 {
        fut.pending()

        fut.await            // block 1 count 14

        ret<i32> = fut.await  // block 0 count 15

        if ret == 15 {
            continue         //          count 18
        }
        fut.await            // block 0 count 19
        break
    }
    if fut.await != 20 {     // block 0 count 20
        os.dief("future state should be 20:%d",int(fut.count))
    }

    //case4 
    fmt.println("case4",int(fut.count))
    fut.pending()
    for i<i32> = fut.await ; i != 0 ; i += 1 { //block 1 count 22

        fut.await //block 0 count 23
        fut.pending()

        while fut.await != 0 { //block 1 count 25
            if fut.await != 29  {
                fut.pending()
                continue
            }else { // count 29
                break
            }
        }
        if fut.await != 30 {
            os.dief("future state should be 30 :%d",int(fut.count))
        }
        break
    }
    return fut.await //count 31

}

fn test_stmt_trifor(){
    fmt.println("test future statement - tri for ")
    poller<runtime.Future> = tstf()

    //11 times
    for i = 0 ; i < 10 ; i += 1 {
        ready<i64> = poller.poll()
        if ready == runtime.PollPending {} else {
            os.dief("future:%d should be pending state",i)
        }
    }
    //last times,is ready
    ready<i64>,result<i32> = poller.poll()
    if ready != runtime.PollReady {
        os.dief("future state should be ready")
    }
    if result != 31 {
        os.die("future state result should be 31")
    }
    fmt.println("test future statement - tri for success")
}
mem GetArrFuture {
    i32 ready
}
GetArrFuture::pending(){this.ready = 0}
GetArrFuture::poll(){
    if !this.ready {
        this.ready = 1
        return runtime.PollPending
    }
    return runtime.PollReady, [1,2,3]
}
async fn tsfr(){
    getarr<GetArrFuture> = new GetArrFuture{}
    //case1
    i = 0
    for k,v : getarr.await {   //block 1
        if k != i os.die("k != i")
        if v != i + 1 os.dief("arr[0] != %d",i + 1)

        i += 1
    }
    //case 2
    i = 0
    getarr.pending()
    for k , v : getarr.await { //block 1
        if k == 1 break
        i += 1
    }
    if i != 1 os.die("case2 should be 1")
    //case 3
    i = 0
    getarr.pending()
    for k,v : getarr.await { //block 1
        if k == 1 continue
        i += 1
    }
    if i != 2 os.die("case3 should be 2")
    //case 4
    fmt.println("case4")
    getarr.pending()
    i = 0
    for k,v : getarr.await { //block 1
        getarr.pending()
        for k2,v2 : getarr.await { //block 1
            if v2 == 2 {
                break
            }
            i += 1
        }
        if v == 2 {
            getarr.pending()
            continue
        }
        getarr.pending()
        i += 1
    }
    if i != 5 os.die("case4 should be 5")
    return [4,5,6]
}

fn test_stmt_forrange(){
    fmt.println("test future statement - for range")
    poller<runtime.Future> = tsfr()

    //7 times
    for i = 0 ; i < 7 ; i += 1 {
        ready<i64> = poller.poll()
        if ready == runtime.PollPending {} else {
            os.dief("future:%d should be pending state",i)
        }
    }
    //last times,is ready
    ready<i64>,arr = poller.poll()
    if ready != runtime.PollReady {
        os.dief("future state should be ready")
    }
    if arr == null os.die("arr is null")
    if arr[0] != 4 || arr[1] != 5 || arr[2] != 6 {
        os.dief("arr != [4,5,6]")
    }
    fmt.println("test future statement - for range success")
}
async fn tsm_ret4(){ return 4.(i8)}
async fn tsm_ret6(){ return 6.(i8)}
async fn tsm(){
    fut<PollFuture> = new PollFuture{}
    //case1
    match fut.await {  //block 1 count 2
        2 : fmt.println("case 1")
        _ : os.die("case 1 failed")
    }
    //case2 
    fut.pending()
    match fut.await { //block 1 count 4
        3  : os.die(" not 3")
        tsm_ret4().await : fmt.println("tsm_ret 4")
        _  : {
            fmt.println(int(fut.count))
            os.die("case2 not default")
        }
    }
    //case 3
    fut.pending()
    match fut.await { //block 1 count 6
        3  : os.die(" not 3")
        tsm_ret6().await : {
            fut.pending()
            ret<i32> = fut.await   // block 1 count 8
            if ret != 8 os.die("fut code not 8")
        }
        _  : os.die("case 3 not default")
    }
    //case 4
    fut.pending()
    match fut.await { //block 1 count 10
        3  : os.die(" not 3")
        10 : {
            fut.pending()
            ret<i32> = fut.await   // block 1 count 12
            if ret != 12 os.die("fut code not 12")
        }
        _  : os.die("case 4 not default")
    }
    //case 4
    fut.pending()
    match fut.count { // 12
        10 : os.die("not 10") 
        tsm_ret4().await : os.die("not tsm 4")
        12 : {
            if fut.await == 14 { //block 1 count 14
                return fut.count
            }else {
                os.die("should be 14")
            }
        }
    }
}

fn test_stmt_match(){
    fmt.println("test future statement - match ")
    poller<runtime.Future> = tsm()

    //11 times
    for i = 0 ; i < 7 ; i += 1 {
        ready<i64> = poller.poll()
        if ready == runtime.PollPending {} else {
            os.dief("future:%d should be pending state",i)
        }
    }
    //last times,is ready
    ready<i64>,result<i32> = poller.poll()
    if ready != runtime.PollReady {
        os.dief("future state should be ready")
    }
    if result != 14 {
        os.die("future state result should be 14")
    }
    fmt.println("test future statement - match success")
}

async fn tms1(){
    return 3,4
}
async fn tms2(){
    return 5,6
}
async fn tms3(){
    return [7,8,9]
}
async fn tms(){
    //case 1
    a,b = tms1().await
    if a != 3 || b != 4 {
        os.die("future result not 3 4")
    }
    //case 2
    a,b = tms1().await,tms2().await
    if a != 3 || b != 5 {
        os.die("future result not 3,5")
    }
    a = tms2().await
    if a != 5 {
        os.die("future result not 5")
    }
    //TOD: case 3
    // if std.len(tms3().await) == 3 {
    // }
    //case 3
    if tms2().await == 5 {
        return tms3().await
    }else {
        return [10,11,12]
    }
}

fn test_multi_stmt(){
    fmt.println("test multi stmt")
    //case1
    fut<runtime.Future> = tms()
    status<i32>,ret = fut.poll()
    if status != runtime.PollReady os.die("future statue not ready")
    if ret == null ||  ret[2] != 9 {
        fmt.println(ret)
        os.die("future result not right")
    }

    fmt.println("test multi stmt success")
}
fn blockon(p<runtime.Future>,blocktime<i32>){
    count<i32> = 0
    ret<i32> = 0
    loop {
        count += 1
        ready<i64>,ret = p.poll()
        if ready == runtime.PollReady {
            break
        }
    }
    if blocktime != count {
        os.dief("blockon != real times")
    }
    return ret
}
fn test_blockon(){
    fmt.println("test block on")
    result<i32> = blockon(tsm(),8.(i32))
    if result != 14 {
        os.die("future state result should be 14")
    }
    fmt.println("test block on success")
}

fn test_rtblockon(){
    fmt.println("test rtblock on")
    result<i32> = runtime.block(tsm())
    if result != 14 {
        os.die("future state result should be 14")
    }
    fmt.println("test rtblock on success")
}
fn main(){
    test_common()
    test_stmt_if()

    test_stmt_while()
    test_stmt_trifor()
    test_stmt_forrange()
    test_stmt_match()
    test_multi_stmt()

    test_blockon()
    test_rtblockon()
}