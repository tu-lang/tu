use fmt
use std
use os
use string

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
    if string.tostring(number) == "3763" {} else {
        os.die("number should be string 3763")
    }
    if string.tonumber("3763") == number {} else {
        os.die("number should be number 3763")
    }

    fmt.println(3)
    c = 'b'
    str = string.tostring(c)
    str += 'c'
    str += '1'
    str += '\t'
    str += '2'
    fmt.println(4)
    if str != "bc1\t2"{
        os.die("char to string failed")
    }

    fmt.println("test string trans success")

}
fn test_itoa(){
    fmt.println("test string itoa")
    sbuf<i8:21> = null
    num<i64> = 1000000000000
    std.itoa(num,&sbuf,16.(i8))
    if ( ret<i8> = std.strcmp(&sbuf,"e8d4a51000".(i8))) == string.Equal {} else {
		os.die("1000000000000 != 0x8d4a51000")
	}

    fmt.println("test string itoa success")
}
func main(){
    #test sub
    test_sub()
    test_split()
    test_trans()
    test_itoa()
}