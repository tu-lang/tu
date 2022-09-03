use os
func test(){
	//compiler parse this file first
	//so the compiler can't recognize the gv is the global MEM var
	//have to take it as plain var
	//handle this should at asmgen period
	gv.b = 100
	if gv.b != 100 os.die("gvb is global mem var, gv.b should be 100")
	gv.a = 200
	if gv.a != 200 os.die("gva is global mem var, gv.a should be 200")
	//check again
	if gv.b != 100 os.die("gvb is global mem var, gv.b should be 100")
	fmt.println("test global mem var assign success")
}