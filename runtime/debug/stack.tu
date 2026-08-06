use fmt
use runtime
use os
use std

CUR_CALLER<i32> = 3

// One OS-thread stack frame; resolve names via findpc at print / L2b only.
mem Frame {
	u64 pc
	u64 sp
	u64 bp
}

FRAME_SIZE<u64> = 24.(u64)

func callerpc(){
	sinfo = stack(CUR_CALLER)
	if std.len(sinfo) >= 3 {
		return sinfo[2]
	}
	return "??:??"
}

// Walk RBP chain into dst[0..max). Returns (filled count, truncated flag).
// dst is the first Frame of a contiguous buffer; max is capacity.
fn capture_stack(dst<Frame>, max<i32>) (i32, i32) {
	if dst == null || max <= 0 {
		return 0.(i32), 0.(i32)
	}
	bp<u64*> = inter_get_bp()
	i<i32> = 0
	truncated<i32> = 0
	base<u64> = dst.(u64)
	while i < max {
		if bp == null {
			break
		}
		pc_slot<u64*> = bp + 8
		rip<u64> = *pc_slot
		if rip == null {
			break
		}
		fr_bits<u64> = base + i.(u64) * FRAME_SIZE
		fr<Frame> = fr_bits.(Frame)
		fr.pc = rip
		fr.bp = bp.(u64)
		fr.sp = bp.(u64) + 16.(u64)
		i += 1
		bp = *bp
	}
	// Buffer full but chain continues → truncated
	if i == max && bp != null {
		pc_slot2<u64*> = bp + 8
		if *pc_slot2 != null {
			truncated = 1
		}
	}
	return i, truncated
}

// Package probe for tests: (n, truncated, first_pc).
fn capture_stack_probe(max<i32>) (i32, i32, u64) {
	if max <= 0 {
		return 0.(i32), 0.(i32), 0.(u64)
	}
	bytes<u64> = FRAME_SIZE * max.(u64)
	raw = std.malloc(bytes)
	dst<Frame> = raw.(Frame)
	n<i32>, trunc<i32> = capture_stack(dst, max)
	pc0<u64> = 0.(u64)
	if n > 0 {
		pc0 = dst.pc
	}
	return n, trunc, pc0
}

// Dynamic string frames for die/print (formats via findpc).
func stack(level<i32>){
	if level <= 0 {
		return []
	}
	bytes<u64> = FRAME_SIZE * level.(u64)
	raw = std.malloc(bytes)
	dst<Frame> = raw.(Frame)
	n<i32>, trunc<i32> = capture_stack(dst, level)
	arr = []
	i<i32> = 0
	base<u64> = dst.(u64)
	// Skip this stack() frame (index 0); user frames start at leaf/caller.
	if n > 0 {
		i = 1
	}
	while i < n {
		fr_bits<u64> = base + i.(u64) * FRAME_SIZE
		fr<Frame> = fr_bits.(Frame)
		// Return address is one past the call; back up for line lookup.
		lookup<u64> = fr.pc
		if lookup > 0.(u64) {
			lookup = lookup - 1.(u64)
		}
		arr[] = findpc(lookup)
		i += 1
	}
	if trunc != 0 {
		arr[] = "...truncated"
	}
	return arr
}
