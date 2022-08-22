use std
use runtime
use string


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
	test_i()
	test_I()
	test_s()
	test_S()
	test_u()
	test_U()
	test_all()
}