
use fmt
use os

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

func main(){
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
