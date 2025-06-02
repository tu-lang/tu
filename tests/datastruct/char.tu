use fmt

func test_equal(){
    fmt.println("test char eq")
    str = "abcde"
    if str[0] == 'b' os.die("stro[0] should be a")
    if str[1] != 'b' os.die("stro[1] should be b")
    if str[2] != 'c' os.die("stro[2] should be c")
    if str[3] != 'd' os.die("stro[3] should be d")
    if str[4] != 'e' os.die("stro[4] should be e")
    //out
    if str[5] != 0   os.die("stro[5] should be outbound")
    fmt.println("test char eq success")
}
func test_unique(){
	fmt.println("test char unique")

	str2<i8*> = "\n\t\'\"\\"
	if str2[0] == '\n' {} else os.die("1") 
	if str2[1] == '\t' {} else os.die("2")
	if str2[2] == '\'' {} else os.die("3")
	if str2[3] == '\"' {} else os.die("4")	

	str = "\n\t\'\"\\"
	if str[0] == '\n' {} else os.die("1") 
	if str[1] == '\t' {} else os.die("2")
	if str[2] == '\'' {} else os.die("3")
	if str[3] == '\"' {} else os.die("4")	
	
	str = "a"
	if str[1] != '\0' os.die("str[1] should be \0")
	if '\n' != 10 os.die(" should be 10") 
	if '\t' != 9  os.die(" should be 9")
	if '\\' != 92 os.die(" should be 92")
	if '\"' != 34 os.die(" should be 34")
	if '\'' != 39 os.die(" should be 39")


	fmt.println("test char unique success")
}
func main(){
	test_equal()
	test_unique()
}