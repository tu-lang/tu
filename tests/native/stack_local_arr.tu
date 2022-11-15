use os
use fmt

func test_var(){
	ga<u8:64> = [
        0, 1, 2, 7, 3, 13, 8, 19,
        4, 25, 14, 28, 9, 34, 20, 40,
        5, 17, 26, 38, 15, 46, 29, 48,
        10, 31, 35, 54, 21, 50, 41, 57,
        63, 6, 12, 18, 24, 27, 33, 39,
        16, 37, 45, 47, 30, 53, 49, 56,
        62, 11, 23, 32, 36, 44, 52, 55,
        61, 22, 43, 51, 60, 42, 59, 58,
	]
	ga[14] = 41
	if ga[14] == 41 {} else os.die("ga[14] != 41")
	if ga[0] == 0 {} else os.die("ga[0] != 0")
	if ga[1] == 1 {} else os.die("ga[1] != 1")
	if ga[7] == 19 {} else os.die("ga[7] != 19")
	if ga[15] == 40 {} else os.die("ga[15] != 40")
	if ga[39] == 39 {} else os.die("ga[39] != 39")
	if ga[55] == 55 {} else os.die("ga[55] != 55")
	fmt.println("test_var success")
}
func test_var_ref(t<u8*>){
	t[14] = 100
	if t[14] == 100 {} else os.die("t[14] != 100")
	if t[0] == 0 {} else os.die("t[0] != 0")
	if t[1] == 1 {} else os.die("t[1] != 1")
	if t[7] == 19 {} else os.die("t[7] != 19")
	if t[15] == 40 {} else os.die("t[15] != 40")
	if t[39] == 39 {} else os.die("t[39] != 39")
	if t[55] == 55 {} else os.die("t[55] != 55")
	fmt.println("test_var_ref success")
}

func main(){
	ga<u8:64> = [
        0, 1, 2, 7, 3, 13, 8, 19,
        4, 25, 14, 28, 9, 34, 20, 40,
        5, 17, 26, 38, 15, 46, 29, 48,
        10, 31, 35, 54, 21, 50, 41, 57,
        63, 6, 12, 18, 24, 27, 33, 39,
        16, 37, 45, 47, 30, 53, 49, 56,
        62, 11, 23, 32, 36, 44, 52, 55,
        61, 22, 43, 51, 60, 42, 59, 58,
	]
	test_var()
	test_var_ref(&ga)
}