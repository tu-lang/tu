use fmt
use runtime
use os

class TestCase {
    ty = ty
    m1 = m1
    m2 = m2
    m3 = m3
    fn init(ty,m1,m2,m3){}
}
case1 = new TestCase(1,11,22,33)
case2 = new TestCase(2,44,55,66)
TestCase::check(){
    match this.ty {
        1: {
            if this.m1 == 11 {} else os.die("check m1 failed")
            if this.m2 == 22 {} else os.die("check m2 failed")
            if this.m3 == 33 {} else os.die("check m3 failed")
        }
        2: {
            if this.m1 == 44 {} else os.die("check m3 failed")
            if this.m2 == 55 {} else os.die("check m4 failed")
            if this.m3 == 66 {} else os.die("check m5 failed")
        }
        _: {
            os.dief("check failed, %d",int(this.ty))
        }
    }
}

mem PollFuture:async {
    i32 ready
    i32 count
}
PollFuture::pending(){this.ready = 0}
PollFuture::poll(ctx){
    this.count += 1
    if !this.ready {
        this.ready = 1 //ready
        return runtime.PollPending
    }
    return runtime.PollReady,this.count
}


async TestCase::tc(){
    this.check()
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
    count = fut.await //block 1  count 2
    if count != 5 {
        os.dief("poll should be 5 times, now:%d",int(count))
    }
    return count
}
TestCase::test_common(){
    fmt.println("test common start")
    this.check()
    v<runtime.Future> = this.tc()
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


async TestCase::tsi(){
    this.check()
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

TestCase::test_stmt_if(){
    fmt.println("test future statement - if")
    this.check()
    poller<runtime.Future> = this.tsi()
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
async TestCase::tsw() {
    this.check()
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

TestCase::test_stmt_while(){
    fmt.println("test future statement - while")
    this.check()
    poller<runtime.Future> = this.tsw()

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

async TestCase::tstf(){
    this.check()
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

TestCase::test_stmt_trifor(){
    fmt.println("test future statement - tri for ")
    this.check()
    poller<runtime.Future> = this.tstf()

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
mem GetArrFuture: async {
    i32 ready
}
GetArrFuture::pending(){this.ready = 0}
GetArrFuture::poll(ctx){
    if !this.ready {
        this.ready = 1
        return runtime.PollPending
    }
    return runtime.PollReady, [1,2,3]
}
async TestCase::tsfr(){
    this.check()
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

TestCase::test_stmt_forrange(){
    fmt.println("test future statement - for range")
    this.check()
    poller<runtime.Future> = this.tsfr()

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
async TestCase::tsm_ret4(){ return 4.(i8)}
async TestCase::tsm_ret6(){ return 6.(i8)}
async TestCase::tsm(){
    this.check()
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
        this.tsm_ret4().await : fmt.println("tsm_ret 4")
        _  : {
            fmt.println(int(fut.count))
            os.die("case2 not default")
        }
    }
    //case 3
    fut.pending()
    match fut.await { //block 1 count 6
        3  : os.die(" not 3")
        this.tsm_ret6().await : {
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
        this.tsm_ret4().await : os.die("not tsm 4")
        12 : {
            if fut.await == 14 { //block 1 count 14
                return fut.count
            }else {
                os.die("should be 14")
            }
        }
    }
}

TestCase::test_stmt_match(){
    fmt.println("test future statement - match ")
    this.check()
    poller<runtime.Future> = this.tsm()

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

async TestCase::tms1(){
    return 3,4
}
async TestCase::tms2(){
    return 5,6
}
async TestCase::tms3(){
    return [7,8,9]
}
async TestCase::tms(){
    this.check()
    //case 1
    a,b = this.tms1().await
    if a != 3 || b != 4 {
        os.die("future result not 3 4")
    }
    //case 2
    a,b = this.tms1().await,this.tms2().await
    if a != 3 || b != 5 {
        os.die("future result not 3,5")
    }
    a = this.tms2().await
    if a != 5 {
        os.die("future result not 5")
    }
    //TOD: case 3
    // if std.len(tms3().await) == 3 {
    // }
    //case 3
    if this.tms2().await == 5 {
        return this.tms3().await
    }else {
        return [10,11,12]
    }
}

TestCase::test_multi_stmt(){
    fmt.println("test multi stmt")
    this.check()
    //case1
    fut<runtime.Future> = this.tms()
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
    result<i32> = blockon(case1.tsm(),8.(i32))
    if result != 14 {
        os.die("future state result should be 14")
    }
    fmt.println("test block on success")
}

fn test_rtblockon(){
    fmt.println("test rtblock on")
    result<i32> = runtime.block(case1.tsm())
    if result != 14 {
        os.die("future state result should be 14")
    }
    fmt.println("test rtblock on success")
}


mem PollFuture2:async {
    i32 ready
    i32 count
}
PollFuture2::pending(){this.ready = 0}
PollFuture2::poll(ctx){
    this.count += 1
    if !this.ready {
        this.ready = 1 //ready
        return runtime.PollPending
    }
    return runtime.PollReady,this.count
}

async TestCase::tc2(){
    fmt.println("test common2")
    this.check()
    fut<PollFuture2> = new PollFuture2{}
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
    count = fut.await //block 1  count 2
    if count != 5 {
        os.dief("poll should be 5 times, now:%d",int(count))
    }
    fmt.println("test common2 success")
    return count
}
fn test_common2(){
    ret<i32> = runtime.block(case1.tc2())
    if ret != 5 {
        os.dief("test cmmon 2 poll should be 5 times")
    }
}
fn test_case1(){
    fmt.println("test member async case 1")
    case1.test_common()
    case1.test_stmt_if()

    case1.test_stmt_while()
    case1.test_stmt_trifor()
    case1.test_stmt_forrange()
    case1.test_stmt_match()
    case1.test_multi_stmt()

    fmt.println("test member async case 1 done")
}

fn test_case2(){
    fmt.println("test member async case 2")
    case2.test_common()
    case2.test_stmt_if()

    case2.test_stmt_while()
    case2.test_stmt_trifor()
    case2.test_stmt_forrange()
    case2.test_stmt_match()
    case2.test_multi_stmt()

    fmt.println("test member async case 2 done")
}

async TestCase::tparg3(a,arr){
    if a == 55 {} else os.die("a != 55")
    if arr[0] == 1 {} else os.die("arr[0] != 1")
    if arr[1] == 2 {} else os.die("arr[1] != 2")
    if arr[2] == 3 {} else os.die("arr[2] != 3")

    return [4,5,6]
}

async TestCase::tparg2(a<i32>,b,c<i64>){
    fmt.println("tparg2 s")
    if a == 10 {} else os.die("a not 10")
    if b >= 20.2  && b <= 20.4{} else os.die("b not 20.3")
    if c == 30 {} else os.die("c not 30")

    ret = this.tparg3(55,[1,2,3]).await
    if ret[0] == 4 {} else os.die("arr[0] != 4")
    if ret[1] == 5 {} else os.die("arr[1] != 5")
    if ret[2] == 6 {} else os.die("arr[2] != 6")

    fmt.println("tparg2 end")
    return "passargs"
}
async TestCase::tparg1(a,b,c){
    fmt.println("tparg1 s")
    if a == 1 {} else os.die("a not 1")
    if b == 2 {} else os.die("b not 2")
    if c == 3 {} else os.die("c not 3")

    v1<i32>  = 10
    v2  = 20.3       
    v3<i64>  = 30
    return this.tparg2(v1,v2,v3).await
}

fn test_passargs(){
    fmt.println("test passargs")

    ret = runtime.block(case1.tparg1(1,2,3))
    if ret == "passargs" {} else os.die("ret not passargs")

    fmt.println("test passargs success")
}
fn main(){
    fmt.println("test async class func member")
    test_case1()
    test_case2()

    test_passargs()

    test_blockon()
    test_rtblockon()
    test_common2()
    fmt.println("test async dyn class func member success")
}