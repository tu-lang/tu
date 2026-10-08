// .await in any expression position inside static (mem / fn) async bodies:
// call arguments, statement conditions, match, compound assignment,
// short-circuit && / ||, returns, unary minus and literal async arguments.
// Real suspension comes from SPend leaves (typed i32 value side).
use fmt
use runtime
use os
use string

mem SInner {
    i32 base
}
async SInner::seven(){ return 7.(i8) }
async SInner::plus(x<i32>){ return x + this.base }
// Two typed params of different widths.
async SInner::mix(a<i32>, b<i64>){ return a + b + this.base }
// Nullable mem param.
async SInner::opt(p<SInner>){
    if p == null return 1.(i8)
    return 2.(i8)
}

// Typed leaf that stays Pending `left` times; counts every poll.
mem SPend: async {
    i32 left
    i32 polls
    i32 val
}
SPend::poll(ctx) i32, i32 {
    this.polls += 1
    if this.left > 0 {
        this.left -= 1
        return runtime.PollPending, 0.(i32)
    }
    return runtime.PollReady, this.val
}
fn spend(left<i32>, v<i32>) SPend { return new SPend{left: left, polls: 0, val: v} }
fn sadd(a<i32>, b<i32>) i32 { return a + b }

// Package-level async with typed params (literal / negative / char / float args).
async sfree(x<i32>, y<f64>, c<i8>, u<u64>){
    if y < 2.49 || y > 2.51 os.die("sfree y")
    if c != 'a' os.die("sfree c")
    if u != 7 os.die("sfree u")
    return x + 1
}
async sdouble(x<i64>){ return x * 2 }
async sf32(g<f32>){
    if g < 0.49 || g > 0.51 os.die("sf32 g")
    return 1.(i8)
}

mem SOut {
    SInner* in2
    SPend*  p1
    SPend*  p2
    i32     hits
}
SOut::id(a<i32>) i32 { return a }
async SOut::seven(){ return 7.(i8) }
async SOut::truth(){
    this.hits += 1
    return 1.(i8)
}

// Awaits in call args, member args, nested args and through a typed local.
async SOut::pending(){
    a<i32> = sadd(spend(1, 5).await, 1)
    b<i32> = this.p1.await + this.p2.await
    c<i32> = sadd(spend(2, 3).await, this.in2.plus(spend(1, 1).await).await)
    p<SPend> = spend(1, 9)
    d<i32> = p.await * 2
    e<i32> = this.id(sadd(spend(1, 2).await, spend(2, 3).await))
    // 6 + (4 + 6) + (3 + 11) + 18 + 5
    return a + b + c + d + e
}

// Awaits in if / else-if / single-line if / while / for / single-line while.
async SOut::conds(){
    t<i32> = 0
    if sadd(this.seven().await, 0) == 1 {
        t = 1
    } else if spend(1, 7).await == 7 {
        t = 2
    } else {
        t = 3
    }
    if spend(1, 3).await > 2 t += 10
    if this.in2.plus(0.(i32)).await != 10 t += 99999
    i<i32> = 0
    while i < spend(1, 3).await {
        i += 1
    }
    t += i * 100
    for j<i32> = 0 ; j < this.id(this.seven().await) - 5 ; j += 1 {
        t += 1000
    }
    while t < 10000 t += spend(1, 5000).await
    // 2 + 10 + 300 + 2000 = 2312 -> + 5000 + 5000 = 12312
    return t
}

// Awaits in match conditions and match arm bodies.
async SOut::matches(){
    r<i32> = 0
    match sadd(this.seven().await, 1) {
        8 : r += 1
        _ : r += 100
    }
    m<i32> = 3
    match m {
        3 : r += spend(1, 10).await
        _ : r += 0
    }
    match spend(1, 4).await {
        4 : {
            x<i32> = this.in2.plus(1.(i32)).await
            r += x * 100
        }
        _ : r += 0
    }
    match this.in2.plus(spend(1, 2).await).await {
        12 : r += 10000
        _ : r += 0
    }
    // 1 + 10 + 1100 + 10000
    return r
}

// Awaits on the right of compound assignment, nested in member args.
async SOut::compound(){
    t<i32> = 1
    t += this.seven().await
    t *= spend(1, 3).await
    t -= sadd(spend(2, 4).await, 0)
    t += this.in2.plus(this.in2.plus(spend(1, 1).await).await).await
    // ((1 + 7) * 3 - 4) + 21 = 41
    u<i32> = 100
    u /= spend(1, 4).await
    u %= this.seven().await
    // 41 * 100 + 25 % 7
    return t * 100 + u
}

// Short-circuit: the right side must not run when the left decides.
async SOut::logic(){
    z<i32> = 0
    if z && this.truth().await {
        os.die("static && rhs evaluated")
    }
    o<i32> = 1
    if o || this.truth().await {} else {
        os.die("static || must be true")
    }
    if (z || spend(1, 1).await) && this.truth().await {} else {
        os.die("static grouped must be true")
    }
    if spend(1, 0).await && this.truth().await {
        os.die("static pending false && x")
    }
    k<i32> = 0
    while k < 5 && (k < 2 || this.truth().await) && this.hits < 4 {
        k += 1
    }
    // hits: 1 + 3 = 4, k = 4
    return k * 10 + this.hits
}

// Awaits inside return expressions (value side stays static).
async SOut::rets(c<i32>){
    if c == 1 {
        return sadd(spend(1, 4).await, 1)
    }
    if c == 2 return this.seven().await.(i32) * spend(1, 2).await
    return this.in2.plus(spend(2, 5).await).await
}
// Static result through a chain of async callers declared before the callee.
async SOut::chain1(){ return this.chain2().await + 1 }
async SOut::chain2(){ return this.in2.plus(spend(1, 3).await).await }

// Unary minus on awaited values and static expressions.
async SOut::negs(){
    a<i32> = -spend(1, 4).await
    b<i32> = -this.in2.plus(2.(i32)).await
    c<i32> = 10 - -spend(1, 3).await
    d<i32> = -sadd(spend(1, 1).await, 1)
    // -4 - 12 + 13 - 2
    return a + b + c + d
}

// Literal / negative / null arguments to async calls with typed params.
async SOut::litargs(){
    r<i32> = this.in2.plus(1).await
    r += this.in2.plus(-4).await
    q<i64> = 5
    r += this.in2.mix(3, q).await
    r += this.in2.mix(spend(1, 2).await, 20).await
    o1<i8> = this.in2.opt(null).await
    o2<i8> = this.in2.opt(this.in2).await
    // 11 + 6 + 18 + 32
    return r * 100 + o1 * 10 + o2
}

// Receiver stored as raw u64 bits and retyped with .(T) before the async call.
mem SRaw {
    u64 bits    // SInner heap pointer
    i32 hits
}
// Sync member handing back a typed pending leaf.
SInner::pend(n<i32>) SPend { return spend(1, n + this.base) }
async SRaw::viaField(){ return this.bits.(SInner).plus(3.(i32)).await }
async SRaw::viaLocal(){
    b<u64> = this.bits
    r<i32> = b.(SInner).seven().await
    r += b.(SInner).pend(2).await
    return r
}
async SRaw::shapes(){
    b<u64> = this.bits
    s<i32> = sadd(b.(SInner).plus(1.(i32)).await, 1)
    if b.(SInner).seven().await == 7 && this.bits.(SInner).plus(0).await == 10 {
        s += 100
    }
    s += this.bits.(SInner).mix(1, 2.(i64)).await * 1000
    return s
}
// Static fn returning the un-awaited future of an asserted receiver.
fn sraw_fut(b<u64>) { return b.(SInner).plus(5.(i32)) }

fn s_check(name<i8*>, got<i64>, want<i64>){
    if got != want {
        os.dief("%s want %d got %d", name, want, got)
    }
    fmt.println("await expr static", string.new(name), "ok")
}

fn main(){
    fmt.println("test await expr static")
    i<SInner> = new SInner{base: 10}
    o<SOut> = new SOut{in2: i, p1: spend(1, 4), p2: spend(2, 6), hits: 0}
    s_check(*"pending", runtime.block(o.pending()), 53)
    // p1 / p2 polled until ready: 1 + 1 and 2 + 1
    s_check(*"pending polls", o.p1.polls * 10 + o.p2.polls, 23)
    s_check(*"conds", runtime.block(o.conds()), 12312)
    s_check(*"matches", runtime.block(o.matches()), 11111)
    s_check(*"compound", runtime.block(o.compound()), 4104)
    s_check(*"logic", runtime.block(o.logic()), 44)
    s_check(*"rets1", runtime.block(o.rets(1.(i32))), 5)
    s_check(*"rets2", runtime.block(o.rets(2)), 14)
    s_check(*"rets3", runtime.block(o.rets(3)), 15)
    s_check(*"chain", runtime.block(o.chain1()), 14)
    s_check(*"negs", runtime.block(o.negs()), -5)
    s_check(*"litargs", runtime.block(o.litargs()), 6712)
    s_check(*"sfree", runtime.block(sfree(41, 2.5, 'a', 7)), 42)
    s_check(*"sdouble", runtime.block(sdouble(-21)), -42)
    g<i64> = runtime.block(sf32(0.5))
    s_check(*"sf32", g, 1)
    r<SRaw> = new SRaw{bits: i, hits: 0}
    s_check(*"assert field", runtime.block(r.viaField()), 13)
    s_check(*"assert local", runtime.block(r.viaLocal()), 19)
    s_check(*"assert shapes", runtime.block(r.shapes()), 13112)
    s_check(*"assert fut", runtime.block(sraw_fut(r.bits)), 15)
    fmt.println("test await expr static success")
}
