
use fmt
use os
use std

func test_int(b){
    fmt.printf("test int return  %d \n",b)
    if  b != 1 {
        fmt.printf("Error %d\n",b)
        os.exit(1)
    }
    return 2
}
func test_string(str){
    fmt.printf("test string return  %s \n",str)
    return str + "return"
}

// Bare return on its own line must not swallow the next typed assign.
mem RetCore {
    i32 flag
}
fn bump_after_bare_return(bits<u64>) {
    if bits == 0 return
    c<RetCore> = bits.(RetCore)
    c.flag = c.flag + 1
}
fn bump_after_braced_return(bits<u64>) {
    if bits == 0 {
        return
    }
    c<RetCore> = bits.(RetCore)
    c.flag = c.flag + 1
}
// Same-line return value and comma-continued multi-return still work.
fn same_line_return(v<i32>) i32 {
    if v != 0 return v
    return 0
}
fn multi_return_comma_newline() i32,i32 {
    return 1,
        2
}

// Callee with two returns; used to test `return callee()` forwarding.
fn pair_ok() i32,i32 {
    return 7, 11
}

// Must forward both values (not drop the second to genDefault 0).
fn forward_pair() i32,i32 {
    return pair_ok()
}

// Member-call path: same forwarding through ChainExpr / MemberCallExpr.
mem PairBox {
    i32 a
    i32 b
}
PairBox::as_pair() i32,i32 {
    return this.a, this.b
}
fn forward_member_pair() i32,i32 {
    p<PairBox> = new PairBox
    p.a = 3
    p.b = 5
    return p.as_pair()
}

func test_bare_return_newline(){
    c<RetCore> = new RetCore
    c.flag = 0
    bits<u64> = c.(u64)
    bump_after_bare_return(bits)
    if c.flag != 1 os.die("bare return newline assign")
    bump_after_braced_return(bits)
    if c.flag != 2 os.die("braced return assign")
    if same_line_return(7) != 7 os.die("same-line return")
    a<i32>, b<i32> = multi_return_comma_newline()
    if a != 1 || b != 2 os.die("comma newline multi-return")
    f1<i32>, f2<i32> = forward_pair()
    if f1 != 7 || f2 != 11 os.die("return callee() multi-return forward")
    m1<i32>, m2<i32> = forward_member_pair()
    if m1 != 3 || m2 != 5 os.die("return member() multi-return forward")
    fmt.println("test bare return newline success")
}

// Composite literals (map / array / closure / new class) in any return slot.
class RetObj {
    v = 0
    func init(v){ this.v = v }
    func pair(){ return this.v, {"v": this.v} }
    func trio(){
        v = this.v
        return [v, v + 1], fn(){ return v * 10 }, new RetObj(v + 2)
    }
}
func ret_map2(){ return 2, {"k": 7} }
func ret_maps(){ return {"a": 1}, {"b": 2} }
func ret_arr_closure(){ return 1, [8, 9], fn(x){ return x * 2 } }
func ret_obj(){ return 0, new RetObj(4) }
func ret_four(){ return "s", [1], {"m": [2, 3]}, new RetObj(5) }
func ret_nested(n){
    if n > 0 {
        return n, {"inner": {"n": n}}, [fn(){ return n }]
    }
    return 0, null, []
}
// Boxed static values next to composite literals.
func ret_mixed(){
    a<i32> = 4
    b<i64> = 6
    return int(a), [int(a), int(b)], {"b": int(b)}
}

func test_composite_returns(){
    p, q = ret_map2()
    if p != 2 || q["k"] != 7 os.die("int, map")
    m1, m2 = ret_maps()
    if m1["a"] != 1 || m2["b"] != 2 os.die("map, map")
    r1, r2, r3 = ret_arr_closure()
    if r1 != 1 || r2[1] != 9 || r3(5) != 10 os.die("int, array, closure")
    s1, s2 = ret_obj()
    if s1 != 0 || s2.v != 4 os.die("int, new class")
    f1, f2, f3, f4 = ret_four()
    if f1 != "s" || f2[0] != 1 || f3["m"][1] != 3 || f4.v != 5 os.die("four slots")
    n1, n2, n3 = ret_nested(3)
    nf = n3[0]
    if n1 != 3 || n2["inner"]["n"] != 3 || nf() != 3 os.die("nested composite")
    z1, z2, z3 = ret_nested(0)
    if z1 != 0 || z2 != null || std.len(z3) != 0 os.die("null / empty array slots")
    // class methods
    o = new RetObj(7)
    o1, o2 = o.pair()
    if o1 != 7 || o2["v"] != 7 os.die("method int, map")
    t1, t2, t3 = o.trio()
    if t1[1] != 8 || t2() != 70 || t3.v != 9 os.die("method array, closure, class")
    // mixed static values
    x1, x2, x3 = ret_mixed()
    if x1 != 4 || x2[1] != 6 || x3["b"] != 6 os.die("mixed boxed slots")
    fmt.println("test composite returns success")
}

func main(){
    test_composite_returns()
    a = 1
    b = test_int(a)
    if  b != 2 {
        fmt.printf("Error %d\n",b)
        os.exit(1)
    }
    fmt.printf("test int return success ret:%d\n",b)

    if  a != 1 {
        fmt.printf("Error %d\n",a)
        os.exit(1)
    }

    str = test_string("str-")
    if  str != "str-return" {
        fmt.printf("Error %s\n",str)
        os.exit(1)
    }
    fmt.printf("test string return success ret:%s\n",str)
    test_bare_return_newline()
}
