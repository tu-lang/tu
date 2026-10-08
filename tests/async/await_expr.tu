// .await in any expression position inside dynamic async bodies:
// call arguments, literals, index, new, unary, statement contexts, chains,
// postfix after .await, dynamic future values, and short-circuit && / ||.
// Real suspension comes from AwPend leaves handed out by plain dynamic funcs.
use fmt
use runtime
use os

// Leaf that stays Pending `left` times, then yields the stored dynamic value.
mem AwPend: async {
    i32 left
    u64 dv     // dynamic Value bits handed in by the caller
}
AwPend::poll(ctx){
    if this.left > 0 {
        this.left -= 1
        return runtime.PollPending
    }
    return runtime.PollReady, this.dv
}
fn aw_pend1(dv<u64>) AwPend { return new AwPend{left: 1, dv: dv} }
fn aw_pend2(dv<u64>) AwPend { return new AwPend{left: 2, dv: dv} }

// Dynamic factories: sync funcs returning leaves that suspend once / twice.
func awslow(v){ return aw_pend1(v) }
func awslow2(v){ return aw_pend2(v) }

// Receiver with async members returning plain values, objects and futures.
class AwW {
    hits = 0
    base = 0
    func init(b){ this.base = b }
    func add(a, b){ return a + b }
    func pair(a){ return a, a + 1 }
    func id(a){ return a }
    // Sync member handing back a pending leaf (awaited via a local).
    func slowv(v){ return aw_pend1(v) }
    // Sync member handing back an un-awaited async-member future.
    func futv(){ return this.seven() }
    // Sync member handing back a leaf produced by a dynamic package func.
    func slowf(v){ return awslow2(v) }
}
async AwW::seven(){ return 7 }
// Async member that really suspends before yielding v.
async AwW::slow(v){
    p = this.slowv(v)
    return p.await
}
async AwW::name(){ return "aw" }
async AwW::neg(){ return -3 }
async AwW::dict(){
    d = {"a": 1, "b": 2}
    return d
}
async AwW::plusbase(x){ return x + this.base }
async AwW::truth(){
    this.hits += 1
    return true
}
async AwW::falsy(){
    this.hits += 1
    return false
}
async AwW::self(){ return this }
async AwW::list(){ return [1, 2, 3] }
// Returns an un-awaited future value.
async AwW::fut(){ return this.seven() }

// Holder reached through member chains.
class AwH {
    cur
    arr
    tf
    func init(){
        this.cur = new AwW(10)
        this.arr = []
    }
}
// Plain constructor argument sink.
class AwBox {
    v = 0
    func init(x){ this.v = x }
}

func awplus(a, b){ return a + b }
// Sync func handing back a future produced by a dynamic call.
func awgetfut(w){ return w.seven() }

// Awaits nested in call arguments.
async aw_args(){
    w = new AwW(10)
    h = new AwH()
    r1 = awplus(w.seven().await, 1)
    r2 = w.add(w.seven().await, 2)
    r3 = h.cur.add(w.seven().await, 3)
    a, b = w.pair(w.seven().await)
    r4 = awplus(awplus(w.seven().await, 1), w.seven().await)
    r5 = w.plusbase(w.seven().await).await
    // 8 + 9 + 10 + 7 + 8 + 15 + 17
    return r1 + r2 + r3 + a + b + r4 + r5
}

// Awaits inside literals, new, index and unary operands.
async aw_literals(){
    w = new AwW(10)
    arr = [w.seven().await, 1]
    m = {"k": w.seven().await}
    bx = new AwBox(w.seven().await)
    idx = [100, 200, 300, 400, 500, 600, 700, 800]
    e = idx[w.seven().await]
    n = ~w.seven().await
    nb = !w.seven().await
    if nb {
        return 0
    }
    g = []
    g[] = w.seven().await
    // 7 + 1 + 7 + 7 + 800 + (~7 = -8) + 7
    return arr[0] + arr[1] + m["k"] + bx.v + e + n + g[0]
}

// Nested awaits in conditions, loops, match, compound assignment and return.
async aw_contexts(){
    w = new AwW(10)
    total = 0
    if awplus(w.seven().await, 1) == 8 {
        total += 1
    }
    i = 0
    while i < awplus(w.seven().await, -4) {
        i += 1
    }
    total += i * 10
    for j = 0 ; j < w.id(w.seven().await) - 5 ; j += 1 {
        total += 100
    }
    match awplus(w.seven().await, 0) {
        7 : total += 1000
        _ : total += 0
    }
    total += w.add(w.seven().await, 0)
    // 1 + 30 + 200 + 1000 + 7 = 1238
    return total + awplus(w.seven().await, 0) * 10000
}

// Chain awaits, futures held in variables / indexes / fields, postfix after .await.
async aw_chains(){
    w = new AwW(10)
    h = new AwH()
    r1 = h.cur.seven().await
    f = h.cur.seven()
    r2 = f.await
    futs = [h.cur.seven(), w.seven()]
    r3 = futs[0].await + futs[1].await
    r4 = w.self().await.base
    r5 = w.self().await.add(1, 2)
    r6 = w.list().await[2]
    r7 = w.fut().await.await
    h.arr[] = h.cur.seven()
    r8 = h.arr[0].await
    r9 = h.cur.self().await.base
    r10 = (w.seven()).await
    h.tf = w.seven()
    r11 = h.tf.await
    // 7 + 7 + 14 + 10 + 3 + 3 + 7 + 7 + 10 + 7 + 7
    return r1 + r2 + r3 + r4 + r5 + r6 + r7 + r8 + r9 + r10 + r11
}

// Futures produced by plain dynamic calls.
async aw_dynvalues(){
    w = new AwW(10)
    r1 = awgetfut(w).await
    g = awgetfut(w)
    r2 = g.await
    return r1 + r2
}

// && / || keep short-circuit semantics around awaits.
async aw_logic(){
    w = new AwW(10)
    a = false
    if a && w.truth().await {
        os.die("&& evaluated rhs await with false lhs")
    }
    b = true
    if b || w.truth().await {} else {
        os.die("|| with true lhs must be true")
    }
    if w.hits != 0 {
        os.dief("short-circuit want 0 hits got %d", w.hits)
    }
    c = true
    r1 = c && w.truth().await
    d = false
    r2 = d || w.falsy().await
    if w.hits != 2 {
        os.dief("rhs awaits want 2 hits got %d", w.hits)
    }
    if w.truth().await && w.falsy().await {
        os.die("true && false must be false")
    }
    if w.falsy().await || w.truth().await {} else {
        os.die("false || true must be true")
    }
    if w.falsy().await && w.truth().await {
        os.die("false && x must be false")
    }
    if w.hits != 7 {
        os.dief("lhs awaits want 7 hits got %d", w.hits)
    }
    i = 0
    while i < 3 && w.truth().await {
        i += 1
    }
    n = 0
    if r1 {
        n += 1
    }
    if r2 {
        n += 10
    }
    // n == 1, hits == 10
    return n + w.hits * 100
}

// Awaits that really suspend: leaves from funcs, members, vars, fields, indexes.
async aw_pending(){
    w = new AwW(10)
    h = new AwH()
    r1 = awplus(100, awslow(5).await)
    r2 = w.add(w.slow(1).await, w.slow(2).await)
    r3 = [awslow2(3).await, w.slow(4).await]
    p = awslow(6)
    r4 = p.await + awslow2(7).await
    h.tf = awslow(8)
    r5 = h.tf.await * 2
    h.arr[] = awslow2(9)
    r6 = h.arr[0].await + w.seven().await
    // 105 + 3 + 7 + 13 + 16 + 16
    return r1 + r2 + r3[0] + r3[1] + r4 + r5 + r6
}

// else-if chains whose conditions await (ready and pending).
async aw_elseif(){
    w = new AwW(10)
    t = 0
    if awplus(w.seven().await, 0) == 1 {
        t = 1
    } else if awplus(w.seven().await, 0) == 7 {
        t = 2
    } else {
        t = 3
    }
    u = 0
    if w.seven().await > 100 {
        u = 1
    } else if w.slow(5).await == 4 {
        u = 2
    } else if awslow(6).await + w.seven().await == 13 {
        u = 3
    } else {
        u = 4
    }
    v = 0
    if false {
        v = 1
    } else if w.falsy().await {
        v = 2
    } else {
        v = w.seven().await
    }
    return t * 100 + u * 10 + v
}

// Range loops over awaited collections; awaits inside the loop body.
async aw_range(){
    w = new AwW(10)
    s = 0
    for v : w.list().await {
        s += v
    }
    for k, v : w.list().await {
        s += k * 10
    }
    for k, v : w.dict().await {
        s += v * 100
    }
    for v : [w.seven().await, awslow(8).await] {
        s += v * 1000
    }
    for v : w.list().await {
        s += w.slow(v).await * 10000
    }
    // 6 + 30 + 300 + 15000 + 60000
    return s
}

// match: awaited subject, awaited case patterns, awaits in case bodies.
async aw_match(){
    w = new AwW(10)
    r = 0
    match 7 {
        w.seven().await : r += 1
        _ : r += 100
    }
    match 5 {
        w.seven().await : r += 100
        awslow(5).await : r += 10
        _ : r += 1000
    }
    match w.slow(3).await {
        1 | 2 : r += 10000
        3 : r += w.seven().await * 1000
        _ : r += 0
    }
    match awplus(w.seven().await, 1) {
        8 : {
            x = w.slow(2).await
            r += x * 100000
        }
        _ : r += 0
    }
    // 1 + 10 + 7000 + 200000
    return r
}

async aw_ret_call(w){ return awplus(w.seven().await, 1) }
async aw_ret_bin(w){ return w.seven().await * w.slow(2).await }
async aw_ret_arr(w){ return [w.seven().await, awslow(3).await] }
async aw_ret_branch(w, c){
    if c {
        return w.slow(4).await + 1
    }
    return w.seven().await - 1
}
async aw_ret_chain(w){ return w.self().await.slow(9).await }

// return of call args / binaries / literals / branches / chains with awaits.
async aw_returns(){
    w = new AwW(10)
    a = aw_ret_arr(w).await
    r = aw_ret_call(w).await + aw_ret_bin(w).await + a[0] + a[1]
    r += aw_ret_branch(w, true).await + aw_ret_branch(w, false).await
    // 8 + 14 + 10 + 5 + 6 + 9
    return r + aw_ret_chain(w).await
}

// Multi-assign with awaits on the right-hand side.
async aw_multi(){
    w = new AwW(10)
    a, b = w.seven().await, w.seven().await + 1
    c, d = awslow(3).await, w.slow(4).await
    e, f = w.pair(awslow2(5).await)
    g, k = [w.seven().await, 1], {"x": awslow(2).await}
    return a * 100000 + b * 10000 + c * 1000 + d * 100 + (e + f) * 10 + g[0] + k["x"]
}

// Awaits in assignment targets (index / key) and in compound assignment.
async aw_lvalue(){
    w = new AwW(10)
    h = new AwH()
    arr = [0, 0, 0, 0]
    arr[w.slow(1).await] = w.seven().await
    arr[awslow(2).await] = awslow2(5).await + 1
    m = {}
    m["k"] = w.slow(7).await + 1
    m[w.name().await] = w.seven().await
    h.cur.base = w.slow(3).await * 2
    h.cur.base += awslow(4).await
    h.cur.base -= w.seven().await
    h.cur.base *= w.slow(5).await
    g = []
    g[] = awslow(11).await
    g[] = w.seven().await + w.slow(1).await
    arr[3] += w.seven().await
    // 7 + 6 + 7 + 8 + 7 + 15 + 11 + 8
    return arr[1] + arr[2] + arr[3] + m["k"] + m["aw"] + h.cur.base + g[0] + g[1]
}

// Awaits re-evaluated on every iteration (body, conditions, init and step).
async aw_loops(){
    w = new AwW(10)
    t = 0
    for i = 0 ; i < 4 ; i += 1 {
        t += awplus(w.slow(i).await, i)
    }
    j = 0
    while j < w.slow(3).await {
        t += awslow2(j).await * 100
        j += 1
    }
    n = 0
    loop {
        n += w.slow(1).await
        if n >= awslow(5).await {
            break
        }
    }
    t += n * 1000
    for k = w.slow(1).await ; k < awslow(3).await ; k += w.slow(1).await {
        t += k * 10000
    }
    // 12 + 300 + 5000 + 30000
    return t
}

// Awaits nested inside the arguments of other awaited calls.
async aw_nested(){
    w = new AwW(10)
    r1 = w.slow(w.slow(w.seven().await).await + 1).await
    r2 = awslow(awslow2(w.plusbase(1).await).await * 2).await
    r3 = w.plusbase(w.plusbase(w.slow(1).await).await).await
    r4 = awplus(w.add(awslow(1).await, w.seven().await), awslow(w.seven().await).await)
    // 8 + 22 + 21 + 15
    return r1 + r2 + r3 + r4
}

// Postfix member / index / call / await after .await.
async aw_postfix(){
    w = new AwW(10)
    r1 = w.self().await.self().await.base
    r2 = w.list().await[0] + w.list().await[2]
    r3 = w.self().await.seven().await + 1
    r4 = w.dict().await["b"]
    r5 = (w.seven()).await * (w.slow(3)).await
    r6 = w.self().await.add(w.seven().await, 1)
    // 10 + 4 + 8 + 2 + 21 + 8
    return r1 + r2 + r3 + r4 + r5 + r6
}

// Comparisons, unary minus, string concat and fmt args over awaits.
async aw_ops(){
    w = new AwW(10)
    r = 0
    if w.seven().await == awslow(7).await {
        r += 1
    }
    if w.seven().await < w.slow(8).await {
        r += 10
    }
    if w.seven().await != w.plusbase(0).await {
        r += 100
    }
    if -w.seven().await == w.neg().await - 4 {
        r += 1000
    }
    s = "x" + w.name().await + "y"
    if s == "xawy" {
        r += 10000
    }
    if fmt.sprintf("%s-%d", w.name().await, w.seven().await) == "aw-7" {
        r += 100000
    }
    return r
}

// Nested / parenthesized short-circuit with pending operands.
async aw_logic2(){
    w = new AwW(10)
    a = false
    if (a || w.truth().await) && w.truth().await {} else {
        os.die("(false || true) && true must be true")
    }
    if (a && w.truth().await) || w.falsy().await {
        os.die("(false && x) || false must be false")
    }
    if w.hits != 3 {
        os.dief("grouped short-circuit want 3 hits got %d", w.hits)
    }
    x = awslow(0).await == 1 && w.truth().await
    y = awslow(1).await == 1 || w.truth().await
    if w.hits != 3 {
        os.dief("pending lhs short-circuit want 3 hits got %d", w.hits)
    }
    z = w.slow(1).await == 1 && w.slow(2).await == 2
    n = 0
    if x {
        n += 1
    }
    if y {
        n += 10
    }
    if z {
        n += 100
    }
    k = 0
    while k < 5 && (k < 2 || w.truth().await) && w.hits < 6 {
        k += 1
    }
    // n == 110, k == 4, hits == 6
    return n + k * 1000 + w.hits * 10000
}

// Value type of an async result is inferred from its return expressions even
// when the callee is declared after the caller (callees below on purpose).
async aw_returns2(){
    // package func result: 2 + 3
    r = aw_r_fcall(1).await + aw_r_fcall(2).await
    // untyped param binaries: 6 * 2
    r += aw_r_parambin(3).await * aw_r_parambin(1).await
    // locals assigned from awaits: 12 + 13
    r += aw_r_local().await + aw_r_local2(3).await
    // await chains through other async funcs: 6 + 12 + 15 - 1
    r += aw_r_dep2().await
    // unary minus of a param / of an awaited value: -3 - 7
    r += aw_r_neg(3).await + aw_r_negaw().await
    // object / closure / string results
    b = aw_r_new().await
    c = aw_r_clos().await
    r += b.v + c(10)
    if aw_r_str().await != "a-aw" {
        os.die("aw_r_str")
    }
    w = new AwW(10)
    o = aw_r_this(w).await
    // 5 + 12 + 25 + 32 - 10 + 5 + 11 + 10 = 90
    return r + o.base
}
async aw_r_dep2(){ return aw_r_dep().await + aw_r_local().await + aw_r_local2(4).await - 1 }
async aw_r_dep(){ return aw_r_parambin(3).await }
async aw_r_fcall(x){ return awplus(x, 1) }
async aw_r_parambin(x){ return x * 2 }
async aw_r_local(){
    s = aw_r_fcall(1).await + 10
    return s
}
async aw_r_local2(x){
    t = aw_r_parambin(x).await
    t += 7
    return t
}
async aw_r_neg(x){ return -x }
async aw_r_negaw(){ return -aw_r_fcall(6).await }
async aw_r_new(){ return new AwBox(5) }
async aw_r_clos(){ return fn(x){ return x + 1 } }
async aw_r_str(){
    s = "a-"
    return s + aw_r_name().await
}
async aw_r_name(){
    w = new AwW(0)
    return w.name().await
}
async aw_r_this(w){ return w }

// obj.syncMethod().await: the method is resolved at run time, so a plain sync
// member returning a leaf / future is awaited just like an async member.
async AwW::slowd(v){ return this.slowv(v).await }
async AwW::futd(){ return this.futv().await + this.slowf(1).await }
async aw_syncmember(){
    w = new AwW(10)
    h = new AwH()
    // 3 + 4 + (7 + 1) + 7 + 2
    r = w.slowv(3).await + w.slowd(4).await + w.futd().await
    r += w.futv().await + w.slowf(2).await
    // member chain receiver: 5
    r += h.cur.slowv(5).await
    if w.slowv(1).await == 1 {
        r += 100
    }
    // call args mixing sync-member and async-member awaits: 2 + 7
    r += w.add(w.slowv(2).await, w.futv().await)
    // loop condition / compound: 3 rounds of +2
    i = 0
    while i < w.slowv(3).await {
        r += w.slowf(2).await
        i += 1
    }
    // 24 + 5 + 100 + 9 + 6 = 144
    return r
}

// Fails the test when got != want.
func aw_check(name, got, want){
    if got != want {
        os.dief("%s want %d got %d", name, want, got)
    }
    fmt.println("await expr", name, "ok")
}

// Receiver retyped by .(T): the async member must be found on the asserted
// mem type even though the caller holds an untyped dynamic value.
mem AwRL: async {
    i32 v
}
AwRL::poll(ctx) i32, i32 { return runtime.PollReady, this.v }
mem AwRM {
    i32 base
}
async AwRM::seven(){ return this.base + 7 }
// Async member returning a dynamic value.
async AwRM::dynv(){ return int(this.base) + 10 }
// Sync member handing back a leaf future.
AwRM::leaf(n<i32>) AwRL { return new AwRL{v: this.base + n} }
// Mem holder: the hop after an asserted head has a static type.
mem AwRH {
    AwRM* m
}
class AwRBox {
    m
    func init(m){ this.m = m }
}
class AwRC {
    m
}
async AwRC::viaAssert(m){ return int(m.(AwRM).seven().await) + 1 }
async AwRC::viaThis(m){
    this.m = m
    return int(this.m.(AwRM).seven().await) + 2
}
async aw_rpkg(m){ return int(m.(AwRM).seven().await) }
async aw_rchain(b){ return int(b.m.(AwRM).seven().await) }
async aw_rarr(a){ return int(a[0].(AwRM).seven().await) }
async aw_rmid(h){ return int(h.(AwRH).m.seven().await) }
async aw_rleaf(m){ return int(m.(AwRM).leaf(5).await) }
// Dynamic-valued async member: result stays dynamic through return.
async aw_rdyn(b){
    v = b.m.(AwRM).dynv().await
    return v
}
async aw_rdyn2(m){ return m.(AwRM).dynv().await }
// Sync func returning the un-awaited asserted future.
func aw_rmkfut(b){ return b.m.(AwRM).seven() }

// Asserted receivers across expression shapes (base 1: seven = 8).
async aw_assertrecv(){
    m<AwRM> = new AwRM{base: 1}
    b = new AwRBox(m)
    h<AwRH> = new AwRH{m: m}
    c = new AwRC()
    s = c.viaAssert(m).await + c.viaThis(m).await          // 9 + 10
    s += aw_rpkg(m).await + aw_rchain(b).await             // 8 + 8
    s += aw_rarr([m]).await + aw_rmid(h).await             // 8 + 8
    s += aw_rleaf(m).await                                 // 6
    s += aw_rdyn(b).await + aw_rdyn2(m).await              // 11 + 11
    f = aw_rmkfut(b)
    s += int(f.await)                                      // 8
    s += awplus(int(b.m.(AwRM).seven().await), 1)          // 9
    if b.m.(AwRM).seven().await == 8 && aw_rpkg(m).await == 8 { s += 100 }
    s += int(b.m.(AwRM).leaf(2).await) * 10                // 30
    return s
}

// Chained call suffix () next to .await in async bodies.
async aw_callsuffix(){
    w = new AwW(10)
    arr = [func(){ return 5 }, func(){ return w.seven() }]
    s = arr[0]() + w.seven().await                         // 12
    s += arr[1]().await                                    // 7
    m = {"f": arr[0]}
    s += m["f"]() * w.seven().await                        // 35
    return s
}

fn main(){
    fmt.println("test await expr dyn")
    aw_check("assertrecv", runtime.block(aw_assertrecv()), 226)
    aw_check("callsuffix", runtime.block(aw_callsuffix()), 54)
    aw_check("args", runtime.block(aw_args()), 74)
    aw_check("literals", runtime.block(aw_literals()), 821)
    aw_check("contexts", runtime.block(aw_contexts()), 71238)
    aw_check("chains", runtime.block(aw_chains()), 82)
    aw_check("dynvalues", runtime.block(aw_dynvalues()), 14)
    aw_check("logic", runtime.block(aw_logic()), 1001)
    aw_check("pending", runtime.block(aw_pending()), 160)
    aw_check("elseif", runtime.block(aw_elseif()), 237)
    aw_check("range", runtime.block(aw_range()), 75336)
    aw_check("match", runtime.block(aw_match()), 207011)
    aw_check("returns", runtime.block(aw_returns()), 52)
    aw_check("multi", runtime.block(aw_multi()), 783519)
    aw_check("lvalue", runtime.block(aw_lvalue()), 69)
    aw_check("loops", runtime.block(aw_loops()), 35312)
    aw_check("nested", runtime.block(aw_nested()), 66)
    aw_check("postfix", runtime.block(aw_postfix()), 53)
    aw_check("ops", runtime.block(aw_ops()), 111111)
    aw_check("logic2", runtime.block(aw_logic2()), 64110)
    aw_check("returns2", runtime.block(aw_returns2()), 90)
    aw_check("syncmember", runtime.block(aw_syncmember()), 144)
    fmt.println("test await expr dyn success")
}
