
use fmt
use time
use os

func test_while(){
    a = 4
    while a != 2 {
        fmt.printf("a=%d\n",a)
        //time.sleep(1)
        a = a - 1
    }
        //time.sleep(3)
    if  a != 2 {
        fmt.printf("failed a:%d should be 2 \n",a)
        os.exit(1)
    }
    fmt.printf("success a:%d should be 2 \n",a)
}

// A leading parenthesized group may be followed by more operators.
func test_while_paren_dyn(){
    // (a || b) && c
    i = 0
    a = false
    while (a || i < 10) && i < 3 {
        i += 1
    }
    if i != 3 os.die("(a || b) && c")
    // (x >= 1 && x <= 5) || y == 0
    x = 1
    y = 1
    n = 0
    while (x >= 1 && x <= 5) || y == 0 {
        x += 1
        n += 1
    }
    if n != 5 os.die("(..) || y == 0")
    // (c) < 3 and chained groups
    c = 0
    while (c) < 3 {
        c += 1
    }
    if c != 3 os.die("(c) < 3")
    s = "abc_12"
    k = 0
    while (k < 6) && (s[k] != '1') {
        k += 1
    }
    if k != 4 os.die("(..) && (..)")
    // whole condition parenthesized still works
    w = 0
    while (w < 2) {
        w += 1
    }
    if w != 2 os.die("(w < 2)")
    fmt.println("test_while_paren_dyn success")
}

// Same shapes with static operands (scanner-style char classes).
fn test_while_paren_static(){
    word<i8*> = "ab_Z9.x".(i8)
    i<i32> = 0
    cn<i8> = word[0]
    while (cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || cn == '_' || (cn >= '0' && cn <= '9') {
        i += 1
        cn = word[i]
    }
    if i != 5 os.die("static ident char class")
    num<i8*> = "12.5e".(i8)
    j<i32> = 0
    dot<i32> = 0
    cd<i8> = num[0]
    while (cd >= '0' && cd <= '9') || (dot == 0 && cd == '.') {
        if cd == '.' dot = 1
        j += 1
        cd = num[j]
    }
    if j != 4 os.die("static number scan")
    k<i32> = 0
    while (k + 1) * 2 < 8 {
        k += 1
    }
    if k != 3 os.die("(k + 1) * 2 < 8")
    // if / for heads with the same leading group
    r<i32> = 0
    if (k > 1 || j < 0) && i == 5 {
        r += 1
    }
    for m<i32> = 0 ; (m < 4 || r == 0) && m < 10 ; m += 1 {
        r += 1
    }
    if r != 5 os.die("if / for leading group")
    fmt.println("test_while_paren_static success")
}

func main(){
    test_while()
    test_while_paren_dyn()
    test_while_paren_static()
}