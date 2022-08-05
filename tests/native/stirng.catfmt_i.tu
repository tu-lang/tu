use string
use std
use runtime
// %s  origin char*
// %S  wrap  string*
// %i  signed int  
// %I  long signed int
// %u  unsigned int
// %U  long unsigned int
// %%  to '%'
// func stringcatfmt(s<i8*>, fmt<i8*>, args,args1,args2,args3)

func test_I(){
    fmt.vfprintf(std.STDOUT,*"test long int  \n")
	// I64_MAX<i64> = 9223372036854775807 	
	// I64_MIN<i64> = -9223372036854775808 	
	ni<i64> = runtime.I64_MIN + 1  //negative
	pi<i64> = runtime.I64_MAX     //positive
	
	strl<i8*> = string.stringcatfmt(string.stringempty(),*"%I-%I",pi,ni)
	strr<i8*> = string.stringnew(*"9223372036854775807--9223372036854775807")

	//negative means not equal
	//positive means strl > s2
	//NOTICE: ret must >= 0 ; cos strl is dynmaic string,the length is not count at \0
	if ( ret<i8> = string.stringcmp(strl,strr) ) < runtime.Zero {
		fmt.vfprintf(
			std.STDOUT,
			*"%s | %s ret:%d l1:%d l2:%d\n",
			strl,strr,ret,
			string.stringlen(strl),string.stringlen(strr)
		)
		os.die("should >= 0")
	}
	//ret must be 0
	if ( ret<i8> = std.strcmp(strl,strr)) != runtime.Zero {
		fmt.vfprintf(
			std.STDOUT,
			*"%s | %s ret:%d l1:%d l2:%d\n",strl,strr
			ret,std.strlen(strl),std.strlen(strr)
		)
		os.die("should == 0")
	}
    fmt.vfprintf(std.STDOUT,*"test long int  success\n")
}
func test_i(){
    fmt.vfprintf(std.STDOUT,*"test int  \n")
	ni<i32> = -13579	  //negative
	pi<i32> = 246810      //positive

	strl<i8*> = string.stringcatfmt(string.stringempty(),*"%i-%i",pi,ni)
	strr<i8*> = string.stringnew(*"246810--13579")

	//negative means not equal
	//positive means strl > s2
	//NOTICE: ret must >= 0 ; cos strl is dynmaic string,the length is not count at \0
	if ( ret<i8> = string.stringcmp(strl,strr) ) < runtime.Zero {
		fmt.vfprintf(
			std.STDOUT,
			*"%s | %s ret:%d l1:%d l2:%d\n",
			strl,strr,ret,
			string.stringlen(strl),string.stringlen(strr)
		)
		os.die("should >= 0")
	}
	//ret must be 0
	if ( ret<i8> = std.strcmp(strl,strr)) != runtime.Zero {
		fmt.vfprintf(
			std.STDOUT,
			*"ret:%d l1:%d l2:%d\n",
			ret,std.strlen(strl),std.strlen(strr)
		)
		os.die("should == 0")
	}
    fmt.vfprintf(std.STDOUT,*"test int  success\n")
}

func main(){
	//test string.stringcatfmt
	test_i() 
	test_I()
}