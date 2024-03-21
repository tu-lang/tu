use fmt
use os	
use string	
use std							
use std.map	
use std.atomic	
use std.regex					
use runtime	
use runtime.debug	
use time	
func test_undefine(){
	{
		a = 1
	}
	//fmt.println(a)//not found
}
func test_common(){
	fmt.println("test_common started")
	if false {
tc:		
		a = 2
		if a == 2 {} else {
			fmt.println(a)
			os.die("should be 2")
		}
		goto tc_end
	}
	a = 4
	goto tc
	
tc_end:
	if a == 4 {} else {
		fmt.println(a)
		os.die("shoulde be 4")
	}
	fmt.println("test_common successed")
}
func test_common_static(){
	fmt.println("test_common static started")
	{
		a<i8> = 20
		goto tcs1
tcs:	
		if a == 20 {} else {
			fmt.println(int(a))
			os.die("should be 20")
		}
		goto tcs_end
	}
tcs1:
	a = 40
	goto tcs
	
tcs_end:
	if a == 40 {} else {
		fmt.println(a)
		os.die("shoulde be 40")
	}
	fmt.println("test_common static successed")	
}

func test_for(){
	fmt.println("test for")
tf:
	arr = [3]
	for(k,v : arr){
		if k == 0 && v == 3 {} else {
			os.die("k != 0 v != 3")
		}
		if false {
tf1:		
			k = 66 //test impact k == 55
			goto tf2
		}
	}

	k = 55
	goto tf1
tf2: 
	if k == 55 {} else {
		os.die("k should be 55")
	}
	//test static var 
	for (i<i32> = 0 ;i < 1 ; i += 1){
		if i == 0 {} else {
			os.die("i != 0 ")
		}
		if false {
tf3:		
			if i == 1 {} else {
				os.die("1 != 1")
			}	
			i = 123 //test impact i = 10000
			goto tf4
		}
	}
	i<i32> = 100000
	goto tf3
tf4:
	if i == 100000 {} else {
		os.die("i != 100000")
	}
	fmt.println("test for successed")
}
func test_if(){
	fmt.println("test if")
	i = 10
	if(i == 10){
		j = 100
		if false {
ti:			
			if j == 100 {} else {
				os.die("j should be 100")
			}
			goto ti1
		}
	}
	j = 200
	goto ti
ti1:
	if j == 200 {} else {
		os.die("j should be 200")
	}

	//test static situation
	i<i32> = 30
	if(i == 30){
		j2<i32> = 30
		if false{
ti2:			
			if j2 == 30 {} else{
				fmt.println(j)
				os.die("j2 should be 30")
				i = 301 //test next i == 300
			}
			goto ti3
		}
	}

	j2 = 300
	goto ti2
ti3:
	if j2 == 300 {} else {
		os.die("j != 300")
	}
	fmt.println("test if success")
}
func test_if_multi(){
	fmt.println("test if multi")
	a = 1
tim_start:
	if(a == 1){
		i<i8> = 111
		if false{
tim1:
			if i == 111 {} else {
				os.die("1 == 111")
			}
			goto tim2
		}
		a = 2
	}else if(a == 2){
		i<i32> = 222
		if false {
tim2:
			if i == 222 {} else {
				os.die("i == 222")
			}
			goto tim3
		}
		a = 3
	}else if(a == 3){
		i = 333
		if false {
tim3:   
			if i == 333 {} else {
				os.die("333")
			}
			goto tim4
		}
		a = 4
	}else{
		i = 444
		if false{
tim4: 	
			if i == 444 {} else {
				os.die("1 == 444")
			}
			goto tim_end2
	  	}
		goto tim_end
	}	
	goto tim_start
tim_end:
	goto tim1
tim_end2:

	fmt.println("test if multi successed")
}
func test_match(){
	a = 1
tm_start:
	match a {
		1 : {
			var = "test"
			a = 2
			if false {
tm1:		
				if var == "test" {} else {
					os.die("var != test")
				}
				goto tm2
			}
		}
		2 : {
			var = 400
			a = 3
			if false {
tm2:		
				if var == 400 {} else {
					os.die("var != 400")
				}
				goto tm3
			}
		}
		_ : {
			var<i32> = 1000
			goto tm_end1
			if false{
tm3:			
				if var == 1000 {} else {
					os.die("var != 1000")
				}
				goto tm_end2
			}
		}
	}
goto tm_start
tm_end1:
	goto tm1
tm_end2:
	//test match level
	arr = [1]
	for(k : arr){
		match 1 {
			1  : continue
		}
	}

}

fn test_while(){
	fmt.println("test_while started")
	i<u32> = 0
	if i == 0 {
		while i == 4 
            i *= 3
	}else{
        b<i32> = 30
	}
	fmt.println("test_while successed")
}
func main(){
	fmt.println("test var scope started")
	test_common()
	test_common_static()
	test_for()
	test_if()
	test_if_multi()
	test_match()	
	test_while()
	fmt.println("test var scope passed")
}
