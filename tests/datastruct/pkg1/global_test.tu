//pkg1.global_a
global_a

use fmt

func change_global(){
    fmt.print("test global1: ",global_a," \n")
    global_a = "change"
    fmt.print("test global1: ",global_a," \n")
}