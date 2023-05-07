use fmt
use os

func equal_not(){
	fmt.println("equal =  or  equal not != test")
	l<i64> = 1
	r      = 1
	if  l == *r {
		l = 10
	}
	if   l != 10 {
		fmt.println("l != 10")
		os.exit(-1)
	}
	r2<i8> = 10
	if  l != r2 {
		fmt.println("l != r2")
		os.exit(-1)
	}
	fmt.println("test equal and not equal pass")
}
func uequal_not(){
	fmt.println("uequal =  or  equal not != test")
	l<u64> = 1
	r      = 1
	if  l == *r {
		l = 10
	}
	if   l != 10 {
		fmt.println("l != 10")
		os.exit(-1)
	}
	r2<u8> = 10
	if  l != r2 {
		fmt.println("l != r2")
		os.exit(-1)
	}
	fmt.println("test equal and not equal pass")
}
func great_than(){
	ul<u8> = 10
	ur<u8> = 20
	if  ul > ur {
		fmt.println("urr should > ul")
		os.exit(-1)
	}
	if  ul >= ur {
		fmt.println("urr should > ul")
		os.exit(-1)
	}

	l<i8>  = 5
	r	   = 10
	if  *r >= l {
		// pass
	}else{
		fmt.println("r should > l")
		os.exit(-1)
	}
	r = 5
	if  *r >= l {
		// pass
	}else{
		fmt.println("r should >= l")
		os.exit(-1)
	}
	r = 4
	if  *r >= l {
		fmt.println(" r should < l")
		os.exit(-1)
	}

	r2<i8> = 4
	if  l > r2 {
		// pass	
	}else{
		fmt.println(" l should > r2")
		os.exit(-1)
	}
	fmt.println("test > & >= success")
}
func less_than(){
	l<i8>  = 10
	r	   = 10
	if  *r <= l {
		// pass
	}else{
		fmt.println("r should > l")
		os.exit(-1)
	}
	r = 9
	if  *r <= l {
		// pass
	}else{
		fmt.println("r should >= l")
		os.exit(-1)
	}
	r = 11
	if  *r <= l {
		fmt.println(" r should < l")
		os.exit(-1)
	}

	r2<i8> = 11
	if  l < r2 {
		// pass	
	}else{
		fmt.println(" l should > r2")
		os.exit(-1)
	}
	ul<u8> = 10
	ur<u8> = 20
	if  ur < ul {
		fmt.println(" ul should < ur")
		os.exit(-1)
	}
	if  ur <= ul {
		fmt.println(" ul should < ur")
		os.exit(-1)
	}
	fmt.println("test < & <= success")
}

// a || b
func log_or(){
	fmt.println("test log_or || condition expression")
	a<i8> = 0
	b<i8> = 0
	if   a || b {
		fmt.println("a || b should be flase")
		os.exit(-1)
	}
	a = 5
	if  a || b {
		a = 0
	}
	if   a || b {
		fmt.println("a || b should be flase")
		os.exit(-1)
	}
	fmt.println("test log_or success")

}
// a && b
func log_and(){
	fmt.println("test log_and || condition expression")
	a<i8> = 0
	b<i8> = 1
	if   a && b {
		fmt.println("a || b should be flase")
		os.exit(-1)
	}
	a = 5
	if  a && b {
		a = 0
	}
	if   a && b {
		fmt.println("a || b should be flase")
		os.exit(-1)
	}
	fmt.println("test log_and success")

}
func main(){
	equal_not()
	uequal_not()
	great_than()
	less_than()
	log_or()
	log_and()
}