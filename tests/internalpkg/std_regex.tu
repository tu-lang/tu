use std.regex
use fmt

func test_replace(){
    fmt.println("test string regex replace")
	str = "/home/user/tu/file.tu"
	dst = "_home_user_tu_file.tu"
	if (ret = regex.replace(str,"/","_") ) != dst {
		os.die(ret + "should be dst")
	}
    fmt.println("test string regex success")

}

func main(){
	test_replace()
}