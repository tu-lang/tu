
use fmt
use os
i = 0
func test_dyn(){
	if i == 1 && os.panic("die if"){}
	if i == 0 || os.panic("die if"){}
	for(j = 0; i == 1 && os.panic("die for") ; j += 1) {
		os.die("die for block")
	}
	for(j = 0; i == 0 || os.panic("die for") ; j += 1) {
		break
	}
	while i == 1 && os.panic("die while") {
		os.die("die for while")
	}
	while i == 0 || os.panic("die while") {
		break
	}
	match i {
		0 | os.panic("die match") : {
			fmt.println("test match ok")
		}
		_ : os.die("die match")
	}
	fmt.println("test dyn && || priority success")
}
j<i8> = 0
func test_native(){
	if j == 1 && os.panic("die") {}
	if j == 0 || os.panic("die") {}
	for(jj<i32> = 0; j == 1 && os.panic("die for") ; jj += 1) {
		os.die("die for block")
	}
	for(jj<i32> = 0; j == 0 || os.panic("die for") ; jj += 1) {
		break
	}
	while j == 1 && os.panic("die while") {
		os.die("die for while")
	}
	while j == 0 || os.panic("die while") {
		break
	}
	match j {
		0 | os.panic("die match") : {
			fmt.println("test match ok")
		}
		_ : os.die("die match")
	}
	fmt.println("test native && || priority success")
}
func main(){
	test_dyn()
	test_native() # should careful to every native codes
}

