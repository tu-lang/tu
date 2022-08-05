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
func test_S(){
    fmt.vfprintf(std.STDOUT,*"test string S \n")
	
	//5sssss-4ssss
	strl<i8*> = string.stringcatfmt(
		string.stringempty(),*"%S-%S",
		string.stringnew(*"5sssss"),
		string.stringnew(*"4ssss")
	)
	strr<i8*> = string.stringnew(*"5sssss-4ssss")

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
    fmt.vfprintf(std.STDOUT,*"test string S success\n")
}

func test_s(){
    fmt.vfprintf(std.STDOUT,*"test string s \n")
	
	//5sssss-4ssss
	strl<i8*> = string.stringcatfmt(string.stringempty(),*"%s-%s",*"5sssss",*"4ssss")
	strr<i8*> = string.stringnew(*"5sssss-4ssss")

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
    fmt.vfprintf(std.STDOUT,*"test string s success\n")
}
func main(){
	//test string.stringcatfmt
	test_s() 
	test_S()

}