
use fmt
use os
use pkg1
use pkg2

use pkg1.case as case1
use pkg2.case as case2

func main(){
    fmt.println("use fmt.println\n")
    pkg1.test()
    pkg2.test()

    c1 = case1.case()
    if c1 == "pkg1.case" {} else 
        os.die("should be pkg1.case")
    c2 = case2.case()
    if c2 == "pkg2.case" {} else 
        os.die("should be pkg2.case")
    fmt.println("import test done\n")
}