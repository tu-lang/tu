// Package-level mem globals must be .balign'd after .string packing (gas+ld).
// Misaligned Note/MutexInter futex words caused STW hangs under link_gcc.

use fmt
use os
use runtime

// Mirrors MutexInter + Note packing that STW depends on.
mem AlignBox {
	u64 key
	u32 note
}

g_box<AlignBox:> = null
g_i32_after_string<i32> = 0

fn test_global_mem_align8() {
	fmt.println("test_global_mem_align8")
	p<u64> = &g_box
	if (p & 7.(u64)) != 0 {
		os.dief("g_box misaligned:%p (need 8-byte)", p)
	}
	note_addr<u64> = p + 8.(u64)
	if (note_addr & 3.(u64)) != 0 {
		os.dief("g_box.note misaligned:%p", note_addr)
	}
	fmt.println("test_global_mem_align8 passed")
}

fn test_global_i32_align4() {
	fmt.println("test_global_i32_align4")
	p<u64> = &g_i32_after_string
	if (p & 3.(u64)) != 0 {
		os.dief("g_i32_after_string misaligned:%p", p)
	}
	fmt.println("test_global_i32_align4 passed")
}

fn test_runtime_sched_align() {
	fmt.println("test_runtime_sched_align")
	// Sched lives in .data after runtime filename .string; must stay 8-aligned
	// for stopnote futex under gas+ld (mother link_gcc).
	p<u64> = &runtime.sched
	if (p & 7.(u64)) != 0 {
		os.dief("runtime.sched misaligned:%p", p)
	}
	fmt.println("test_runtime_sched_align passed")
}

fn test_mutex_futex_on_aligned_global() {
	fmt.println("test_mutex_futex_on_aligned_global")
	m<runtime.MutexInter:> = null
	m.init()
	m.lock()
	m.unlock()
	fmt.println("test_mutex_futex_on_aligned_global passed")
}

fn main() {
	test_global_mem_align8()
	test_global_i32_align4()
	test_runtime_sched_align()
	test_mutex_futex_on_aligned_global()
	fmt.println("all global_data_align tests passed")
}
