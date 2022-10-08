use fmt
use std
use os
use time

func test(){
	fmt.println("signal handler")
	os.exit(0)
}
func main(){
	os.setsignal(os.SIGINT,test)
	fmt.println("register signal")
	//kill self
	kstr = fmt.sprintf(
		"kill -2 %d",
		os.getpid()
	)
	fmt.println(kstr)
	//kill self
	os.shell(kstr)
	time.sleep(2)
	os.die("register signal failed,not should be here")
}
