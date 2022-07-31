use fmt
use std
use os


func test_open_read(filepath,fstr){
    fmt.println("test open/read file:",filepath)
	file = new std.File(filepath)
	if !file.IsOpen() {
		os.die("open file failed")
	}

	//test size
	if file.Size() != std.len(fstr) {
		os.die("assert file body size failed" + file.Size() )
	}
	body = file.ReadAll()
	fmt.println(std.len(body),std.len(fstr))
	if body != fstr {
		fmt.println(body,fstr)
		os.die("file body assert failed")
	}
    fmt.println("test open/read file passed")
}

func main(){
	fstr = "1111111111
2222222222
3333333333
4444444444
5555555555
6666666666
7777777777
8888888888
9999999999
10"
    test_open_read("./file/file.txt",fstr)
}