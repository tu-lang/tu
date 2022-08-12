use fmt
use init
use os

func init(){
    fmt.println("main init")
    init.total = 0
}
func main(){
    if init.total != 3 os.die("something wrong here")
    fmt.println("test init called by automatic successful")
}