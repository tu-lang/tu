use pkg1
use pkg1.pkg2
use os
use nest
use nest.nest1
use nest.nest1.nest2

func test_nest(){
    // the reason of this wired if statment usage :
    // `if lhs != rhs` => if lhs is null or rhs is null will lead the entirly result is false
    if nest.map[0] == "nest" {} else 
        os.panic("nes.map:%s should be nest",nest.map[0])
    if nest1.map[0] == "nest1" {} else 
        os.panic("nest1.map:%s should be nest1",nest1.map[0])
    if nest2.map[0] == "nest2" {} else 
        os.panic("nest2.map:%s should be nest2",nest2.map[0])

    nest2.map["xxx"] = "yyy"
    if nest2.map["xxx"] == "yyy" {} else
        os.panic("nest2.map[\"xxx\"]:%s should be yyy",nest2.map["xxx"])

    fmt.println("test multi layer pacakge global kv value op success")
}
func common(){
    pkg1.test()
    pkg2.test()
    if  pkg2.obj != "pkg1.pkg2.obj" {
        fmt.println("pkg1.pkg2 test failed")
        os.exit(-1)
    }
    fmt.println("pkg1.pkg2 test pass res:",pkg2.obj)
}

func main(){
    common()
    test_nest()
}