// Cross-pkg fn.(u64) must store a bare code entry (not FuncObject*).
// Calling via fc<sig> must match a same-package fn.(u64) path.

use fmt
use os
use fnptr_owner as owner

fn sig4(a<u64>, b<u64>, c<u64>, d<u64>) (u64)
fn sig1(a<u64>) (u64)

fn local_add4(a<u64>, b<u64>, c<u64>, d<u64>) u64 {
	return a + b + c + d
}

fn test_same_pkg_fc(){
	fmt.println("test_same_pkg_fc")
	bits<u64> = local_add4.(u64)
	f<sig4> = bits.(u64)
	got<u64> = f(1, 2, 3, 4)
	if got != 10 {
		os.die("same-pkg fc add4 != 10")
	}
	fmt.println("test_same_pkg_fc success")
}

fn test_cross_pkg_fc(){
	fmt.println("test_cross_pkg_fc")
	bits<u64> = owner.owner_add4.(u64)
	f<sig4> = bits.(u64)
	got<u64> = f(1, 2, 3, 4)
	if got != 10 {
		os.die("cross-pkg fc add4 != 10")
	}
	bits1<u64> = owner.owner_add1.(u64)
	f1<sig1> = bits1.(u64)
	got1<u64> = f1(41)
	if got1 != 42 {
		os.die("cross-pkg fc add1 != 42")
	}
	fmt.println("test_cross_pkg_fc success")
}

fn test_cross_pkg_direct(){
	fmt.println("test_cross_pkg_direct")
	got<u64> = owner.owner_add4(10, 20, 30, 40)
	if got != 100 {
		os.die("cross-pkg direct != 100")
	}
	fmt.println("test_cross_pkg_direct success")
}

fn main(){
	test_same_pkg_fc()
	test_cross_pkg_direct()
	test_cross_pkg_fc()
}
