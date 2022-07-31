
use pkg1
use pkg1.pkg2
use os

func main(){
    pkg1.test()
    pkg2.test()
    if  pkg2.obj != "pkg1.pkg2.obj" {
        fmt.println("pkg1.pkg2 test failed")
        os.exit(-1)
    }
    fmt.println("pkg1.pkg2 test pass res:",pkg2.obj)
}