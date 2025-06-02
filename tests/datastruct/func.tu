
use fmt
use pkg1
use os

fn func_noargs() {
    fmt.println("no args test")
}
fn func_withargs(a,b,c) {
    if  a != 1 {
        fmt.print("[failed] func_withargs a != 1 :",a,"\n")
        os.exit(1)
    }
    if  b != "iamb" {
        fmt.print("[failed] func_withargs b != iamb :",b,"\n")
        os.exit(1)
    }
    if  c[0] != "c[0]" {
        fmt.print("[failed] func_withargs c[0] != c[0] :",c,"\n")
        os.exit(1)
    }
    fmt.println(a,b,c)
    fmt.println("has args test")
}

fn test_passfn(fc){
    arr = ["c[0]"]
    fc(1,"iamb",arr)
}
fn main(){
    fc = func_noargs
    fc(1)
    fwn = func_withargs
    arr = ["c[0]"]
    fwn(1,"iamb",arr)
    p1 = pkg1.test
    p1()
    p2 = pkg1.test2
    p2()

    test_passfn(fwn)
}
