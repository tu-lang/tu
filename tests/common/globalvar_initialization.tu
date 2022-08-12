use fmt
use os

use var

func main(){
	if var.allcheck != 4 {
		os.die("should be 4")
	}
	fmt.println("test global var automatic initialization passed")
}