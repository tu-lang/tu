mem Obj {
	i8   a,b
	Obj* next
}
t<Obj>
use runtime.gc

func test_speed()
{
	fmt.println("test_speed")
    for (i<i32> = 0 ; i < 1000000 ; i += 1) {
        size<i32> = 30
		p<u64*> = gc.gc_malloc(size)
		*p = size
    }
}
func test_logic(){
	fmt.println("test_logic")
	p1<Obj> = gc.gc_malloc(sizeof(Obj))
    p1.a = 10
    p1.b = 20
	hdr<gc.Block> = p1 - 8
    gc.gc()
	if p1.a != 10 {
		os.die("p1.a != 10")
	}
	if p1.b != 20 {
		os.die("p1.b != 20")
	}
    p1.next = gc.gc_malloc(sizeof(Obj))
	if p1.next == null {
		os.die("p1.next == null")
	}
    p1.next.a = 22
    p1.next.b = 33
    gc.gc()
	if p1.next.a != 22 {
		os.die("p1.next.a != 22")
	}
	if p1.next.b != 33{
		os.die("p1.next.b != 33")
	}
	fmt.println("test_logic right")
}
func main(){
	//gc is unstable right now
	//gc.gc_init()
	//test_logic()
	//test_speed()

}