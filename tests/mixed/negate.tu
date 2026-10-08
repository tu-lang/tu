// Unary minus across static and dynamic operands in one expression:
// boxed static values, dynamic values fed to static fns, mixed binaries.
use fmt
use os

mem NegMix {
    i32 a
    i64 b
}
fn neg_si(x<i32>) i32 { return -x }

class NegDyn {
    v = 4
    func init(){}
    func neg(){ return -this.v }
}

fn test_negate_mixed(){
    a<i32> = 5
    m<NegMix> = new NegMix{a: 7, b: 11}
    x = 3
    o = new NegDyn()
    // boxed static operands
    if -int(a) != -5 os.die("-int(a)")
    if -int(m.b) != -11 os.die("-int(m.b)")
    // static negation boxed into dynamic binaries
    z = -int(m.a) + x
    if z != -4 os.die("-int(m.a) + x")
    z2 = int(-a) * -x
    if z2 != 15 os.die("int(-a) * -x")
    // dynamic negation combined with boxed static values
    if -x != -int(m.a) + 4 os.die("-x != -int(m.a) + 4")
    if -o.v + int(a) != 1 os.die("-o.v + int(a)")
    // static fn results mixed with dynamic negation
    if int(neg_si(-a)) != 5 os.die("neg_si(-a)")
    if -o.neg() + int(neg_si(a)) != -1 os.die("-o.neg() + neg_si(a)")
    fmt.println("test_negate_mixed success")
}

fn main(){
    test_negate_mixed()
}
