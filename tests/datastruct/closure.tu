
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

    fmt.println("[pass] closure test")


}
