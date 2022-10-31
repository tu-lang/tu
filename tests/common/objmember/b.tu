use fmt
use os

func test(){
	globalvar.var1["s"] = "22"
	for name,v : globalvar.var1 {
		gname = globalvar.getpkgname()
		if gname !=  "test" os.die("test failed")
	}
	fmt.println("test passed, globalmember.call")
}