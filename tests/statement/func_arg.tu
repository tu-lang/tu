
use fmt
use os

func equal_6(a,b,c,d,e,f){
    fmt.println("equal_6:\n")
    fmt.println("res:%d %d %d %d %d %d \n",a,b,c,d,e,f)
}
func over_6(a,b,c,d,e,f,h,i,j)
{
    fmt.println("over_6:\n")
    if  a != 1 {
        fmt.println("a == 1 failed",a)
        os.exit(1)
    }
    if  b != 2 {
        fmt.println("b == 2 failed",b)
        os.exit(1)
    }
    if  c != 3 {
        fmt.println("c == 3 failed",c)
        os.exit(1)
    }
    if  d != 4 {
        fmt.println("d == 4 failed",d)
        os.exit(1)
    }
    if  e != 5 {
        fmt.println("e == 5 failed",e)
        os.exit(1)
    }
    if  f != 6 {
        fmt.println("f == 6 failed",f)
        os.exit(1)
    }
    if  h != 7 {
        fmt.println("h == 7 failed",h)
        os.exit(1)
    }
    if  i != 8 {
        fmt.println("i == 8 failed",i)
        os.exit(1)
    }
    if  j != "this is j" {
        fmt.println("j == this is j failed",j)
        os.exit(1)
    }
    fmt.println("res:%d %d %d %d %d %d %d %d %s\n",a,b,c,d,e,f,h,i,j)
}

func main(){
    equal_6(1,2,3,4,5,6)

    over_6(1,2,3,4,5,6,7,8,"this is j")
}