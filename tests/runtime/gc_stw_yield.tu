// newcore workers that only osyield must still join GC STW.
// Without osyield checking gcwaiting, runtime.GC() hangs forever.
// Teardown uses core_join (CLEARTID), not sleep.

use fmt
use os
use runtime

ready_cnt<i32> = 0
done_flag<i32> = 0

fn worker_spin() {
    ready_cnt = ready_cnt + 1
    loop {
        runtime.osyield()
        if done_flag != 0 {
            return
        }
    }
}

fn test_gc_stw_with_osyield_workers() {
    fmt.println("test_gc_stw_with_osyield_workers")
    ready_cnt = 0
    done_flag = 0
    c0<u64> = runtime.newcore(worker_spin.(u64))
    c1<u64> = runtime.newcore(worker_spin.(u64))
    c2<u64> = runtime.newcore(worker_spin.(u64))
    c3<u64> = runtime.newcore(worker_spin.(u64))
    spins<i32> = 0
    while ready_cnt < 4 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 {
            os.die("workers never ready")
        }
    }
    runtime.GC()
    done_flag = 1
    runtime.core_join(c0)
    runtime.core_join(c1)
    runtime.core_join(c2)
    runtime.core_join(c3)
    fmt.println("test_gc_stw_with_osyield_workers passed")
}

fn main() {
    test_gc_stw_with_osyield_workers()
}
