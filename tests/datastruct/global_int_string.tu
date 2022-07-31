
// this is a global variable
global_a

use fmt
use os

use pkg1

func current_pkg()
{
    global_a = "test"
}
func current_pkg_test(){

    global_a = 1
    if  global_a != 1 {
        fmt.println("test global int failed")
        os.exit(1)
    }
    fmt.println("test global int successed")

    current_pkg()
    if  global_a != "test" {
        fmt.println("test global string failed")
        os.exit(1)

    }
    fmt.println("test global string success ",global_a)

}

func other_pkg_test()
{
    pkg1.global_a = 1000
    if  pkg1.global_a != 1000 {
        fmt.println("other pkg test int failed",pkg1.global_a)
        os.exit(1)
    }
    fmt.print("pkg1.globals: ",pkg1.global_a, " \n")

    pkg1.change_global()
    if  pkg1.global_a != "change" {
        fmt.println("other pkg test string failed",pkg1.global_a)
        os.exit(1)
    }
    fmt.println(pkg1.global_a)
    
}


func main(){
    current_pkg_test()
    other_pkg_test()
}
