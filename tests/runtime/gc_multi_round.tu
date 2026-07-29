// Multi-round GC with osyield workers.

use fmt
use os
use runtime
use time

ready<i32> = 0
done<i32> = 0

fn worker() {
    ready = ready + 1
    loop {
        runtime.osyield()
        if done != 0 return
    }
}

fn main() {
    fmt.println("test_gc_multi_round")
    i<i32> = 0
    while i < 2 {
        runtime.newcore(worker.(u64))
        i += 1
    }
    spins<i32> = 0
    while ready < 2 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("workers never ready")
    }
    runtime.GC()
    runtime.GC()
    done = 1
    time.sleep(1)
    fmt.println("test_gc_multi_round passed")
}
