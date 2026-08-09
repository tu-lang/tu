// Static path: native type-asserted integer literals in binary operators.
// Must compile to OperatorHelper, not runtime_binary_operator (SEGV).

use fmt
use os

fn test_assert_lit_shift() {
	v<u64> = 1.(u64) << 30
	if v != 1073741824.(u64) {
		os.die("static 1.(u64)<<30")
	}
}

fn test_assert_lit_add_cmp() {
	s<i32> = 8.(i32) + 4.(i32)
	if s != 12 {
		os.die("static 8.(i32)+4.(i32)")
	}
	n<u64> = 64.(u64)
	if n > 1.(u64) << 30 {
		os.die("static compare with asserted shift")
	}
}

fn test_assert_lit_assign_compound() {
	w<u64> = 2.(u64)
	w = w << 10.(u64)
	if w != 2048.(u64) {
		os.die("static var << asserted lit")
	}
	w += 1.(u64)
	if w != 2049.(u64) {
		os.die("static += asserted lit")
	}
}

fn main() {
	test_assert_lit_shift()
	test_assert_lit_add_cmp()
	test_assert_lit_assign_compound()
	fmt.println("assert_lit_binop static ok")
}
