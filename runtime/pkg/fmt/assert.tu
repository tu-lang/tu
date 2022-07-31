
use os

func assert(a,b,str){
	check<u8> = str
	if  a != b  {
		expr = "assert: " + a + " != " + b
		println(expr)
		if  int(check)  != null {
			msg  = "warmsg: " + str
			println(msg)
		}
		os.exit(-1)
	}
}