use fmt
use std.map
use string

func hashkey(k<string.String>){
    return k.hash64()
}

func test_int(){
	fmt.println("test in key")
    m<map.Map> = map.map_new(0.(i8),0.(i8))

    m.insert(1.(i8),11.(i8))
    m.insert(2.(i8),22.(i8))
    m.insert(3.(i8),33.(i8))
    m.insert(4.(i8),44)

	v<i32> = 33
	if m.find(3.(i8)) == v {} else {
		os.die("m[3] != 33")
	}
    fmt.println(int(m.find(3.(i8))))
    m.insert(3.(i8),333.(i8))
    fmt.println(int(m.find(3.(i8))))
    fmt.println(m.find(4.(i8)))
	v = 333
	if m.find(3.(i8)) == v {} else {
		os.die("m[3] != 333")
	}
	fmt.println("test in key success")
}
func test_string(){
	fmt.println("test string")
    m<map.Map> = map.map_new(hashkey,0.(i8))
    m.insert(string.S(*"test1"),1)
    m.insert(string.S(*"test2"),2)
    m.insert(string.S(*"test3"),3)
	if m.find(string.S(*"test3")) == 3 {} else{
		os.die("m[test3] != 3")
	}
	m.insert(string.S(*"test3"),3000.(i8))
    b<u64> = m.find(string.S(*"test3"))
	if b == 3000 {} else {
		os.die("m[test3] != 3000")
	}
    fmt.println(int(b))
    fmt.println(m.find(string.S(*"test2")))
	fmt.println("test string success")
}
func test_iter(){

    m<map.Map> = map.map_new(map.Null,map.Null)
    m.insert(1.(i8),11.(i8))
    m.insert(2.(i8),22.(i8))
    m.insert(3.(i8),33.(i8))

    iter<map.MapIter> = m.iter()
    while iter.next() != map.End {
        fmt.println(int(iter.k()),int(iter.v()))
    }
	fmt.println("test iter success")

}
func main(){
    test_int()
    test_string()
	test_iter()
}