
use os

export func assert(a, b, str){
	if  a != b  {
		expr = "assert: " + a + " != " + b
		println(expr)
		if  str != null {
			msg  = "warmsg: " + str
			println(msg)
		}
		os.exit(-1)
	}
}