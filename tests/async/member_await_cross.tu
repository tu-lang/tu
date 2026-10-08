// Cross-pkg member-async .await must resolve leaf in the owner package
// (genawait2 pkg annot aligned with leafawait). Second block_on must stay healthy.
// Also: untyped assign from typed factory + materialize leaf then .await.
use fmt
use os
use runtime
use await_owner as own

mem LocalLock {
    i32 n
}
async LocalLock::lock() {
    return 3.(i8)
}

async cross_lock_once() {
    m<own.Lock> = new own.Lock { n: 0 }
    return m.lock().await
}

async cross_pending_once() {
    m<own.Lock> = new own.Lock { n: 0 }
    return m.pending_then_ready().await
}

async local_lock_once() {
    m<LocalLock> = new LocalLock { n: 0 }
    return m.lock().await
}

// Untyped receiver: m = own.lock_new() must propagate Lock so m.lock().await is static.
async cross_untyped_recv_await() {
    m = own.lock_new()
    return m.lock().await
}

// Materialize member-async leaf then await the local (fut = m.lock(); fut.await).
async cross_materialize_leaf_await() {
    m = own.lock_new()
    fut = m.lock()
    return fut.await
}

async cross_ready_var_await() {
    a<own.ReadyLeaf> = own.ready_new(10.(i8))
    return a.await
}

async cross_ready_binop_assign() {
    a<own.ReadyLeaf> = own.ready_new(10.(i8))
    b<own.ReadyLeaf> = own.ready_new(20.(i8))
    sum<i8> = a.await + b.await
    return sum
}

fn test_cross_member_await() {
    fmt.println("test_cross_member_await")
    r1<i64> = runtime.block(cross_lock_once())
    if r1 != 1 {
        os.die("cross lock().await != 1")
    }
    // Second block_on: poison check after cross-pkg member-async.
    r2<i64> = runtime.block(local_lock_once())
    if r2 != 3 {
        os.die("follow-up local lock poisoned")
    }
    fmt.println("test_cross_member_await success")
}

fn test_cross_pending_await() {
    fmt.println("test_cross_pending_await")
    r<i64> = runtime.block(cross_pending_once())
    if r != 2 {
        os.die("cross pending_then_ready().await != 2")
    }
    r2<i64> = runtime.block(local_lock_once())
    if r2 != 3 {
        os.die("follow-up after pending poisoned")
    }
    fmt.println("test_cross_pending_await success")
}

fn test_cross_untyped_recv() {
    fmt.println("test_cross_untyped_recv")
    r<i64> = runtime.block(cross_untyped_recv_await())
    if r != 1 {
        os.die("untyped recv lock().await != 1")
    }
    r2<i64> = runtime.block(local_lock_once())
    if r2 != 3 {
        os.die("follow-up after untyped recv poisoned")
    }
    fmt.println("test_cross_untyped_recv success")
}

fn test_cross_materialize_leaf() {
    fmt.println("test_cross_materialize_leaf")
    r<i64> = runtime.block(cross_materialize_leaf_await())
    if r != 1 {
        os.die("materialize leaf await != 1")
    }
    r2<i64> = runtime.block(local_lock_once())
    if r2 != 3 {
        os.die("follow-up after materialize poisoned")
    }
    fmt.println("test_cross_materialize_leaf success")
}

fn test_cross_ready_leaf_poll() {
    fmt.println("test_cross_ready_leaf_poll")
    r<i64> = runtime.block(cross_ready_var_await())
    if int(r.(i8)) != 10 {
        os.dief("ReadyLeaf.await want 10 got %d", int(r.(i8)))
    }
    r2<i64> = runtime.block(cross_ready_binop_assign())
    if int(r2.(i8)) != 30 {
        os.dief("ReadyLeaf sum assign want 30 got %d", int(r2.(i8)))
    }
    r3<i64> = runtime.block(local_lock_once())
    if r3 != 3 {
        os.die("follow-up after ready leaf poisoned")
    }
    fmt.println("test_cross_ready_leaf_poll success")
}

// Mixed: a dynamic class body awaits a mem leaf straight into a static fn
// argument; a mem body awaits a dynamic future straight into a func argument.
class AwMix {
    k = 0
    func init(){}
}
async AwMix::nine(){ return 9 }
fn awmix_add(a<i32>, b<i32>) i32 { return a + b }
func awmix_dyn(a, b){ return a + b }

async AwMix::static_leaf_arg(){
    m<LocalLock> = new LocalLock { n: 0 }
    r<i32> = awmix_add(m.lock().await, 4)
    return int(r) + awmix_dyn(this.nine().await, 1)
}
async LocalLock::dyn_arg(d){
    return awmix_dyn(d.nine().await, 1)
}

fn test_cross_await_args() {
    fmt.println("test_cross_await_args")
    mx = new AwMix()
    r = runtime.block(mx.static_leaf_arg())
    if r != 17 {
        os.dief("class body: static leaf arg want 17 got %d", r)
    }
    m<LocalLock> = new LocalLock { n: 0 }
    r2 = runtime.block(m.dyn_arg(mx))
    if r2 != 10 {
        os.dief("mem body: dynamic future arg want 10 got %d", r2)
    }
    fmt.println("test_cross_await_args success")
}

// Leaf with a typed value side that stays Pending `left` times.
mem XPend: async {
    i32 left
    i32 polls
    i32 val
}
XPend::poll(ctx) i32, i32 {
    this.polls += 1
    if this.left > 0 {
        this.left -= 1
        return runtime.PollPending, 0.(i32)
    }
    return runtime.PollReady, this.val
}
fn xpend(left<i32>, v<i32>) XPend { return new XPend{left: left, polls: 0, val: v} }
// Leaf yielding a dynamic value, suspending once (awaitable from dynamic code).
mem XDPend: async {
    i32 left
    u64 dv     // dynamic Value bits
}
XDPend::poll(ctx){
    if this.left > 0 {
        this.left -= 1
        return runtime.PollPending
    }
    return runtime.PollReady, this.dv
}
fn xdpend(dv<u64>) XDPend { return new XDPend{left: 1, dv: dv} }
fn xadd(a<i32>, b<i32>) i32 { return a + b }
func xdyn(a, b){ return a + b }

// Dynamic receiver used from both class and mem bodies.
class XC {
    hits = 0
    xm      // XM held untyped; retyped with .(XM) at await sites
    func init(){}
    // Sync members handing back a dynamic leaf / an async-member future.
    func leaf(v){ return xdpend(v) }
    func futn(){ return this.nine() }
}
async XC::nine(){ return 9 }
async XC::truth(){
    this.hits += 1
    return true
}
async XC::nope(){
    this.hits += 1
    return false
}
async XC::word(){ return "mix" }

// Dynamic body: static leaves in conditions, literals and short-circuit.
async XC::dconds(){
    r = 0
    if xpend(1, 4).await == 4 { r += 1 }
    if xadd(xpend(2, 3).await, 1) > 3 { r += 10 }
    m<own.Lock> = new own.Lock { n: 0 }
    if m.pending_then_ready().await == 2 && this.truth().await { r += 100 }
    if xpend(1, 0).await || this.nope().await { r += 9000 } else { r += 1000 }
    arr = [int(xpend(1, 5).await), this.nine().await]
    if arr[0] + arr[1] == 14 { r += 10000 }
    return r
}
// Dynamic body: while / match / compound over static leaves.
async XC::dloops(){
    t = 0
    k = 0
    kk<i32> = 0
    while k < int(xpend(1, 3).await) {
        k += 1
        kk += 1
        t += int(xpend(1, kk).await)
    }
    match xpend(2, 6).await {
        6 : t += 100
        _ : t += 0
    }
    t += xdyn(this.nine().await, int(xpend(1, 1).await)) * 1000
    return t
}
// Dynamic results computed from static awaits (boxed with int()).
async XC::fromm(m){
    mm<XM> = m
    return int(mm.seven().await) + 1
}
async XC::fromleaf(){ return int(xpend(2, 6).await) * 2 }
// Dynamic body: sync members returning leaf / future awaited directly.
async XC::syncs(){
    r = this.leaf(3).await + this.futn().await
    r += this.leaf(4).await * 10
    return r
}
// Dynamic body: literal args into typed static async params.
async XC::lits(m){
    mm<XM> = m
    r = int(mm.mixa(3, 1.25).await)
    r += int(mm.mixa(-2, 0.75).await)
    return r
}

mem XM {
    i32 base
}
async XM::seven(){ return 7.(i8) }
async XM::mixa(a<i32>, f<f64>){
    if f < 0.7 || f > 1.3 os.die("mixa f")
    return a + this.base
}
// Static body awaiting dynamic futures in conditions / loops / match.
async XM::mconds(d){
    r = 0
    if d.nine().await == 9 { r += 1 }
    if d.truth().await && this.seven().await == 7 { r += 10 }
    if d.nope().await || d.nine().await > 8 { r += 100 }
    k = 0
    while k < 3 && d.truth().await {
        k += 1
    }
    r += k * 1000
    match d.word().await {
        "mix" : r += 10000
        _ : r += 0
    }
    s = xdyn(d.nine().await, int(this.base)) + int(this.seven().await)
    return r + s * 100000
}
// Static bodies returning values computed from dynamic awaits.
async XM::fromc(d){ return d.nine().await + 1 }
async XM::fromc2(d){
    s = d.nine().await
    return s * 2
}
// Static body: dynamic receiver sync members returning leaf / future.
async XM::syncs(d){
    r = d.leaf(5).await + d.futn().await
    if d.leaf(1).await == 1 { r += 100 }
    return r
}

// Dynamic body: async member of a mem reached through a .(XM) assertion.
async XC::viaAssert(m){
    this.xm = m
    r = int(m.(XM).seven().await) + int(this.xm.(XM).mixa(1, 1.0).await)
    if this.xm.(XM).seven().await == 7 { r += 100 }
    return r
}
// Static body: mem async member reached through a dynamic holder + assertion.
async XM::viaDyn(d){
    r = int(d.xm.(XM).seven().await) * 10
    return r + int(this.base)
}

func x_check(name, got, want){
    if got != want {
        os.dief("%s want %d got %d", name, want, got)
    }
}

fn test_cross_await_positions() {
    fmt.println("test_cross_await_positions")
    c = new XC()
    x_check("dconds", runtime.block(c.dconds()), 11111)
    x_check("dloops", runtime.block(c.dloops()), 10106)
    d = new XC()
    m<XM> = new XM{base: 4}
    x_check("mconds", runtime.block(m.mconds(d)), 2013111)
    // truth x1 + nope x1 + truth x3 (loop stops on k)
    x_check("mconds hits", d.hits, 5)
    fmt.println("test_cross_await_positions success")
}

fn test_cross_await_values() {
    fmt.println("test_cross_await_values")
    c = new XC()
    m<XM> = new XM{base: 4}
    x_check("fromm", runtime.block(c.fromm(m)), 8)
    x_check("fromleaf", runtime.block(c.fromleaf()), 12)
    x_check("syncs", runtime.block(c.syncs()), 52)
    x_check("lits", runtime.block(c.lits(m)), 9)
    x_check("fromc", runtime.block(m.fromc(c)), 10)
    x_check("fromc2", runtime.block(m.fromc2(c)), 18)
    x_check("msyncs", runtime.block(m.syncs(c)), 114)
    // seven 7 + mixa(1) 5 + 100
    x_check("viaAssert", runtime.block(c.viaAssert(m)), 112)
    x_check("viaDyn", runtime.block(m.viaDyn(c)), 74)
    fmt.println("test_cross_await_values success")
}

fn main() {
    test_cross_member_await()
    test_cross_pending_await()
    test_cross_untyped_recv()
    test_cross_materialize_leaf()
    test_cross_ready_leaf_poll()
    test_cross_await_args()
    test_cross_await_positions()
    test_cross_await_values()
}
