
use fmt
use std

func die(str){
    fmt.println(str)
    code<i8> = -1
    std.die(code)
}
func exit(code){
    std.die(*code)
}