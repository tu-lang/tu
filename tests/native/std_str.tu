use fmt
use std
use string

func test_unsigned_longint(){
	longint<string.String> = string.S(
		*"11887393157837578923"
	)
	fmt.println(longint.dyn())
    number<u64> = std.strtoul(longint.str(),0.(i8),10.(i8))	

	dstlongint<string.String> = string.S(
		string.fromulonglong(
			number
		)
	)
	fmt.println(longint.dyn())
	//compare
	if longint.cmp(dstlongint) == string.Equal {} else {
		os.die("long int not equal")
	}
	fmt.println("test unsigned_longint success")
}

func main(){
	test_unsigned_longint()
}