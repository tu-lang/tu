// Walk OS-thread stack: RBP chain fast path; pcsp framesize fallback when BP breaks.

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

fn bp_usable(bp<u64*>) i32 {
	if bp == null {
		return 0
	}
	b<u64> = bp.(u64)
	if (b & 7.(u64)) != 0.(u64) {
		return 0
	}
	return 1
}

// Walk RBP chain into dst[0..max). Falls back to pclntab framesize when BP breaks.
// Returns (filled count, truncated flag).
fn capture_stack(dst<Frame>, max<i32>) (i32, i32) {
	if dst == null || max <= 0 {
		return 0.(i32), 0.(i32)
	}
	bp<u64*> = inter_get_bp()
	sp_now<u64> = inter_get_sp()
	i<i32> = 0
	truncated<i32> = 0
	base<u64> = dst.(u64)
	while i < max {
		rip<u64> = 0.(u64)
		fr_bp<u64> = 0.(u64)
		fr_sp<u64> = 0.(u64)
		if bp_usable(bp) != 0 {
			pc_slot<u64*> = bp + 8
			rip = *pc_slot
			if rip == 0.(u64) {
				break
			}
			fr_bp = bp.(u64)
			fr_sp = bp.(u64) + 16.(u64)
			bp = *bp
			sp_now = fr_sp
		} else {
			// pcsp subset: return PC at sp+framesize-8; advance sp by framesize.
			if i == 0 {
				break
			}
			prev_bits<u64> = base + (i - 1).(u64) * FRAME_SIZE
			prev<Frame> = prev_bits.(Frame)
			lookup<u64> = prev.pc
			if lookup > 0.(u64) {
				lookup = lookup - 1.(u64)
			}
			rec<PclnRec> = findfunc(lookup)
			if rec == null || rec.framesize < 16.(u32) {
				break
			}
			rip = pcsp_next_pc(prev.sp, rec.framesize)
			if rip == 0.(u64) {
				break
			}
			fr_sp = prev.sp + rec.framesize.(u64)
			fr_bp = 0.(u64)
			sp_now = fr_sp
			bp = null
		}
		fr_bits<u64> = base + i.(u64) * FRAME_SIZE
		fr<Frame> = fr_bits.(Frame)
		fr.pc = rip
		fr.bp = fr_bp
		fr.sp = fr_sp
		i += 1
	}
	if i == max {
		if bp_usable(bp) != 0 {
			pc_slot2<u64*> = bp + 8
			if *pc_slot2 != 0.(u64) {
				truncated = 1
			}
		}
	}
	return i, truncated
}

// pcsp subset: given sp and framesize from findfunc, read return PC.
fn pcsp_next_pc(sp<u64>, framesize<u32>) u64 {
	if framesize < 16.(u32) {
		return 0.(u64)
	}
	fs<u64> = framesize.(u64)
	off<u64> = sp + fs - 8.(u64)
	p<u64*> = off
	return *p
}

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
	if n > 0 {
		i = 1
	}
	while i < n {
		fr_bits<u64> = base + i.(u64) * FRAME_SIZE
		fr<Frame> = fr_bits.(Frame)
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

// Return formatted frame for caller skip levels above this helper.
func Caller(skip<i32>){
	level<i32> = skip + 3
	if level < 3 {
		level = 3
	}
	bytes<u64> = FRAME_SIZE * level.(u64)
	raw = std.malloc(bytes)
	dst<Frame> = raw.(Frame)
	n<i32>, trunc<i32> = capture_stack(dst, level)
	idx<i32> = skip + 1
	if n <= idx {
		return "??:??"
	}
	fr_bits<u64> = dst.(u64) + idx.(u64) * FRAME_SIZE
	fr<Frame> = fr_bits.(Frame)
	lookup<u64> = fr.pc
	if lookup > 0.(u64) {
		lookup = lookup - 1.(u64)
	}
	return findpc(lookup)
}

// File path of the caller at skip levels above this helper.
func CallerFile(skip<i32>){
	pc<u64> = caller_pc_at(skip)
	if pc == 0.(u64) {
		return ""
	}
	r<PclnRec> = findfunc(pc)
	if r == null || r.file == 0.(u64) {
		return ""
	}
	return string.new(r.file)
}

// Source line of the caller at skip levels above this helper.
func CallerLine(skip<i32>){
	pc<u64> = caller_pc_at(skip)
	if pc == 0.(u64) {
		return 0
	}
	r<PclnRec> = findfunc(pc)
	if r == null {
		return 0
	}
	return int(funcline(r, pc))
}

fn caller_pc_at(skip<i32>) u64 {
	level<i32> = skip + 3
	if level < 3 {
		level = 3
	}
	bytes<u64> = FRAME_SIZE * level.(u64)
	raw = std.malloc(bytes)
	dst<Frame> = raw.(Frame)
	n<i32>, trunc<i32> = capture_stack(dst, level)
	idx<i32> = skip + 1
	if n <= idx {
		return 0.(u64)
	}
	fr_bits<u64> = dst.(u64) + idx.(u64) * FRAME_SIZE
	fr<Frame> = fr_bits.(Frame)
	lookup<u64> = fr.pc
	if lookup > 0.(u64) {
		lookup = lookup - 1.(u64)
	}
	return lookup
}
