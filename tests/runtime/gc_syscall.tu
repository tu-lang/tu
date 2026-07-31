// Blocking syscall cores must not stall GC STW.
// entersyscall marks CoreSyscall so stopSTW skips them; exitsyscall
// resynchronizes before heap use.

use fmt
use os
use std
use runtime

ready_cnt<i32> = 0
done_flag<i32> = 0

fn worker_nanosleep_loop() {
    ready_cnt = ready_cnt + 1
    loop {
        if done_flag != 0 {
            return
        }
        runtime.entersyscall()
        req<std.TimeSpec:> = null
        rem<std.TimeSpec:> = null
        req.sec = 0
        req.nsec = 20000000
        std.nanosleep(&req, &rem)
        runtime.exitsyscall()
    }
}

fn test_gc_stw_with_syscall_workers() {
    fmt.println("test_gc_stw_with_syscall_workers")
    ready_cnt = 0
    done_flag = 0
    c0<u64> = runtime.newcore(worker_nanosleep_loop.(u64))
    c1<u64> = runtime.newcore(worker_nanosleep_loop.(u64))
    c2<u64> = runtime.newcore(worker_nanosleep_loop.(u64))
    c3<u64> = runtime.newcore(worker_nanosleep_loop.(u64))
    spins<i32> = 0
    while ready_cnt < 4 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 {
            os.die("syscall workers never ready")
        }
    }
    // Several GC rounds while workers sit in nanosleep.
    round<i32> = 0
    while round < 8 {
        runtime.GC()
        round += 1
    }
    done_flag = 1
    runtime.core_join(c0)
    runtime.core_join(c1)
    runtime.core_join(c2)
    runtime.core_join(c3)
    fmt.println("test_gc_stw_with_syscall_workers passed")
}

fn main() {
    test_gc_stw_with_syscall_workers()
}
