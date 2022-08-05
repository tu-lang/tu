use std
use runtime
use string

// %s  origin char*
// %S  wrap  string*
// %i  signed int  
// %I  long signed int
// %u  unsigned int
// %U  long unsigned int
// %%  to '%'
// func stringcatfmt(s<i8*>, fmt<i8*>, args,args1,args2,args3)
func test_all(){
    fmt.vfprintf(std.STDOUT,*"test all  \n")
	v1<i8*> = "v1"
	v2<i8*> = string.stringnew(*"v2")
	v3<i32> = 13579
	v4<i64> = -246810246810
	v5<u32> = 246810
	v6<u64> = 1357913579


	strl<i8*> = string.stringcatfmt(
		string.stringempty(),
		*"%s-%S-%i%I-%u-%U-%%",
		v1,v2,v3,v4,v5,v6
	)
	strr<i8*> = string.stringnew(*"v1-v2-13579-246810246810-246810-1357913579-%")

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
    fmt.vfprintf(std.STDOUT,*"test all  success\n")
}
func main(){
	test_all()
}