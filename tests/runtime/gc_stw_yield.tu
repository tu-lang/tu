// newcore workers that only osyield must still join GC STW.
// Without osyield checking gcwaiting, runtime.GC() hangs forever.

use fmt
use os
use runtime
use time

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
    i<i32> = 0
    while i < 4 {
        runtime.newcore(worker_spin.(u64))
        i += 1
    }
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
    // Give workers a moment to observe done_flag.
    time.sleep(1)
    fmt.println("test_gc_stw_with_osyield_workers passed")
}

fn main() {
    test_gc_stw_with_osyield_workers()
}
