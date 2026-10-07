
use os
use fmt
use std

func test_rand(){
    fmt.println("test_rand")

    // Retry on collision: LCG first-pair equality is seed-dependent (~1%).
    v1 = 0
    v2 = 0
    found = false
    for i = 0; i < 32; i += 1 {
        v1 = std.rand(100)
        v2 = std.rand(100)
        if v1 > 100 os.die("v1 should < 100")
        if v2 > 100 os.die("v2 should < 100")
        if v1 != v2 {
            found = true
            break
        }
    }
    if !found os.die("rand never produced distinct values")

    fmt.println("test_rand success")
}
func test_len(){
    fmt.println("test std.len")
    a = null
	if std.len(a) == 0 {} else os.die("len should be 1 and with warning")
	a = 100
	if std.len(a) == 1 {} else os.die("len should be 1 and with warning")
	a = true
	if std.len(a) == 1 {} else os.die("len should be 1 and with warning")
	a = "test"
	if std.len(a) == 4 {} else os.dief("len should be 4 %d",std.len(a))
	a = [1,2,4,"test"]
	if std.len(a) == 4 {} else os.dief("len should be 4")
	//unsupport map
    fmt.println("test std.len success")
}
gm = {}
func test_hash64(){
	for i = 0 ; i <  100000 ; i += 1 {
		s = i + ""
		l = std.len(s)
		p = int(std.hash64(*s,*l))
		if gm[p] != null {
			os.dief("hashcode conflict %s %s %d",gm[p],s,p)
		}
		gm[p] = s
	}
    fmt.println("test hash64 success")
}
// std.ntime returns a dyn int usable in dyn arithmetic; ntime_ns is the native twin.
func test_ntime(){
    fmt.println("test_ntime")
    t1 = std.ntime()
    if type(t1) != type(1) os.die("std.ntime should return a dyn int")
    if t1 <= 0 os.die("std.ntime should be positive")
    t2 = std.ntime()
    if t2 < t1 os.die("std.ntime should be monotonic enough across calls")
    ms = (t2 - t1) / 1000000
    if ms > 10000 os.dief("std.ntime delta too large: %d", ms)
    fmt.printf("ntime delta ok %d ms\n", ms)

    n1<i64> = std.ntime_ns()
    if n1 <= 0 os.die("std.ntime_ns should be positive")
    if int(n1) < t1 os.die("std.ntime_ns should not go back before std.ntime")

    r = std.srand_i64(100)
    if type(r) != type(1) os.die("std.srand_i64 should return a dyn int")
    if r < 0 || r >= 100 os.dief("std.srand_i64(100) out of range: %d", r)
    big = std.srand_i64(null)
    if big <= 0 os.die("std.srand_i64(null) should be positive")
    fmt.println("test_ntime success")
}
func main(){
    test_rand()
    test_ntime()
    test_hash64()
    // fmt.println("before")
    //os.daemon()
    // fmt.println("after")
}