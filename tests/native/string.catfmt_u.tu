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
func test_u(){
    fmt.vfprintf(std.STDOUT,*"test unsigned  int  \n")
	//FIXME: ni<u32> = -1 == runtime.U32_MAX
	ni<u32> =  246810
	pi<u32> =  13579

	strl<i8*> = string.stringcatfmt(string.stringempty(),*"%u-%u",pi,ni)
	strr<i8*> = string.stringnew(*"13579-246810")

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
    fmt.vfprintf(std.STDOUT,*"test unsigned int  success\n")
}
func test_U(){
    fmt.vfprintf(std.STDOUT,*"test unsigned  long int  \n")
	// U64_MAX<u64> = 18446744073709551615 	
	// U64_MIN<u64> = 0
	ni<u64> =  0xFFFFFFFFFFFFFFFF #18446744073709551615
	pi<u64> = runtime.U64_MAX     #18446744073709551615 

	strl<i8*> = string.stringcatfmt(string.stringempty(),*"%U-%U",pi,ni)
	strr<i8*> = string.stringnew(*"18446744073709551615-18446744073709551615")

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
    fmt.vfprintf(std.STDOUT,*"test unsigned long int  success\n")
}
func main(){
	//test string.stringcatfmt
	test_U()
	test_u()
}