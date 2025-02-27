
use fmt
use os

func string1(){
    return func(){
        return "string00" + 100 + "string"
    }
}

func int1(){
    return func(){
        a = 100
        a += 1
        return a
    }
}
func array1(){
    return func(){
        arr = ["first",1,2]
        arr[] = "fourth"
        return arr
    }
}
func embeded(){
    r = func(){
        c1 = func(){
            c2 = func(){
                c3 = func(){
                    return "c3"
                }
                return c3() + "c2"
            }
            return c2() + "c1"
        }
        return c1() + "r"
    }
    str = r()
    fmt.println(str)
    if str != "c3c2c1r" {
        fmt.println("[failed] embeded closure str != c3c2c1r")
        os.exit(1)
    }
}

fn test_varref(){
    fmt.println("test capture1")
    //case1 capture1
    v1 = 100
    v2 = "test"
    v3 = [1,2,3]
    cf = fn(){
        if v1 == 100 {} else os.die("v1 != 100")
        if v2 == "test" {} else os.die("v2 != test")
        if v3[2] == 3 {} else os.die("v3[2] != 3")
    }
    cf()
    //case 2 static && dyn type refence
    v4<i32> = 44
    v5      = 55
    v6<i8>  = 66
    v7<f32> = 77.3
    v8      = 99
    cf = fn(){
        if v4 == 44 {} else os.die("v4 != 44")
        if v5 == 55 {} else os.die("v5 != 55")
        if v6 == 66 {} else os.die("v6 != 66")
        if v7 >= 77.3 {} else os.die("v7 >= 77.3")
        if v7 <= 77.4 {} else os.die("v7 >= 77.3")
        if v8 == 99 {} else os.die("v8 != 99")
    }
    cf()

    //case 3 pass args 
    cf = fn(v1,v2,v3){
        if v4 == 44 {} else os.die("v4 != 44")
        if v5 == 55 {} else os.die("v5 != 55")
        if v6 == 66 {} else os.die("v6 != 66")
        if v1 == 1 {} else os.die("v1 != 1")
        if v2 == 2 {} else os.die("v2 != 2")
        if v3 == 3 {} else os.die("v3 != 3")
    }
    cf(1,2,3)
    //case 4 pass varidc args
    cf = fn(v1,args...){
        if v4 == 44 {} else os.die("v4 != 44")
        if v5 == 55 {} else os.die("v5 != 55")
        if v1 == 10 {} else os.die("v1 != 10")
        fmt.println(args)
    }
    cf(10,2,3,4)

    //case 5 common

    cf = fn(v1){
        tmp = "test"
        return fn(s){
            if s == "inner" {} else os.die("s != inner")
            fmt.println(s)
            return tmp
        }
    }
    ret = cf()("inner")
    if ret == "test" {} else os.die("ret != test")

    //case 6 pass
    cf = fn(v1){
        p = ret
        f1 = fn(f1){
            ret = f1()
            if ret == "hello" {} else os.die("ret != hello")
        }
        f2 = fn(){
            if p == "test" {} else os.die("p != test")
            return "hello"
        }
        f1(f2)
    }
    cf()


    fmt.println("test capture1 success")
}

func main(){
    fmt.println("closure test")
    embeded()
    a = string1()
    if   a()  != "string00100string" {
        fmt.println("[failed] closure a()!= string")
        os.exit(1)
    }
    fmt.println(a())

    b = int1()
    if   b()  != 101 {
        fmt.println("[failed] closure b()!= 100")
        os.exit(1)
    }
    fmt.println(b())

    c = array1()
    arr = c()
    if  arr[3] != "fourth" {
        fmt.println("[failed] closure c()!= foruth")
        os.exit(1)
    }
    fmt.println(arr)

    test_varref()
    fmt.println("[pass] closure test")
}
