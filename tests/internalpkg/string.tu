use fmt
use std
use os

func test_sub(){
    fmt.println("test string sub")
    arr = ["a.tu","b.tu","c.tu","d.tu"]
    for ( a : arr){
        if string.sub(a,std.len(a) - 3) != ".tu" {
            os.die(a + " the last 3 char should be .tu")
        }
        fmt.println(a,string.sub(a,std.len(a) - 3 ))
    }
    fmt.println("test string sub success")
}
func test_split(){
    fmt.println("test string split")
    str = "/home/user/tu-lang/tu"
    arr = string.split(str,"/")
    right = ["","home","user","tu-lang","tu"]
    for (k,v : arr){
        fmt.println(v)
        if right[k] != v {
            os.die("test_split: assert failed ",right[k],v)
        }
    }

    fmt.println("test string split success")
}
func test_trans(){
    fmt.println("test string trans")
    number = 3763
    if string.tostring(number) != "3763" {
        os.die("number should be string 3763")
    }
    if string.tonumber("3763") != number {
        os.die("number should be number 3763")
    }
    fmt.println("test string trans success")

}




func main(){
    #test sub
    test_sub()
    test_split()
    test_trans()
}