// Feature: packages-asyncio-runtime, Task 1.1: 复用现有 std.clock_gettime + sys.CLOCK_MONOTONIC 并补 smoke 测试
// 关联 R27.3：asyncio.runtime.time.instant.Instant::now 通过 std.clock_gettime(std.CLOCK_MONOTONIC, ts) 取纳秒级单调时钟
use fmt
use std
use os

fn read_monotonic_ns() i64 {
	ts<std.TimeSpec:> = null
	std.clock_gettime(std.CLOCK_MONOTONIC, ts)
	return ts.sec * 1000000000 + ts.nsec
}

fn int_clock_gettime_monotonic(){
	fmt.println("int_clock_gettime_monotonic test")

	first<i64> = read_monotonic_ns()
	if first <= 0 os.dief("clock_gettime returned non-positive ns: %d", first)

	// 连续若干次调用，断言 ns 单调不减（CLOCK_MONOTONIC 永不回退）
	prev<i64> = first
	for i<i32> = 0 ; i < 1024 ; i += 1 {
		curr<i64> = read_monotonic_ns()
		if curr < prev os.dief("CLOCK_MONOTONIC went backwards: prev=%d curr=%d", prev, curr)
		prev = curr
	}

	// 整段测试至少应耗费一些时间（即便循环很快），最终时刻必须 >= 起始时刻
	last<i64> = read_monotonic_ns()
	if last < first os.dief("final ns %d < first ns %d", last, first)

	fmt.println("int_clock_gettime_monotonic passed")
}

fn main(){
	int_clock_gettime_monotonic()
}
