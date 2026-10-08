
use fmt
use os

func test_int(){
    fmt.println("test int minus or negative")

    a = 1 + -1
    if  a != 0 {
        fmt.println("test 1 -1 != 0 failed")
        os.exit(1)
    }
    a = 1 - 1
    if  a != 0 {
        fmt.println("test 1 - 1 != 0 failed")
        os.exit(1)
    }

    a = 1 + 1
    if  a != 2 {
        fmt.println("test 1 1 != 2 failed")
        os.exit(1)
    }
    fmt.println("test int passed!")
}
func test_string(){
    fmt.println("test string add operate by compiler")
    a = 100 + "test"
    if  a != "100test" {
        fmt.println("test 100 test != 100test failed")
        os.exit(1)
    }
    fmt.println("test string add operate by compiler passed")
}
func test_arg(str){
    fmt.print("test string arg:",str,"\n")
    if  str != "3str1str2str34str4" {
        fmt.println("test str arg failed! str:",str)
        os.exit(1)
    }
    fmt.println("test string arg passed")

}

// Receiver for unary minus on dynamic members.
class NegC {
    v = 4
    f = 1.5
    func init(){}
    func neg(){ return -this.v }
    func get(){ return this.v }
}
func neg_dg(){ return 6 }
func neg_ret(x){ return -x }

// Unary minus on non-literal dynamic operands.
func test_negate_dyn(){
    x = 3
    y = 1.5
    if -x != -3 os.die("-x")
    if -y != -1.5 os.die("-y")
    // call results
    if -neg_dg() != -6 os.die("-neg_dg()")
    if -neg_dg() * -neg_dg() != 36 os.die("-f() * -f()")
    if neg_ret(x) != -3 os.die("return -x")
    if -neg_ret(x) != 3 os.die("-neg_ret(x)")
    // members / methods / index
    o = new NegC()
    if -o.v != -4 os.die("-o.v")
    if -o.f != -1.5 os.die("-o.f")
    if o.neg() != -4 os.die("o.neg()")
    if -o.get() + 1 != -3 os.die("-o.get() + 1")
    arr = [1, 2]
    if -arr[1] != -2 os.die("-arr[1]")
    mp = {"k": 5}
    if -mp["k"] != -5 os.die("-mp[k]")
    // nesting / binary contexts
    if -(-x) * 2 != 6 os.die("-(-x) * 2")
    if x - -x != 6 os.die("x - -x")
    if -(x + 1) != -4 os.die("-(x + 1)")
    // compound assignment / call args / string concat
    t = 0
    t += -x
    t -= -o.v
    if t != 1 os.die("t += -x")
    if fmt.sprintf("%d", -x) != "-3" os.die("sprintf -x")
    if "n" + -x != "n-3" os.die("concat -x")
    fmt.println("test_negate_dyn success")
}

func main(){
    test_int()
    test_string()
    test_negate_dyn()
    test_arg(1 + 2 + "str1" + "str2" + "str3" + 4 + "str4")
}