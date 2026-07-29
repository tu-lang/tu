// GC STW correctness with newcore OS threads.
// Validates osyield checking gcwaiting + locks/mallocing guards.

use fmt
use os
use runtime
use time

// ---- Test 1: basic osyield workers + forced GC ----

t1_ready<i32> = 0
t1_done<i32> = 0

fn worker_osyield() {
    t1_ready = t1_ready + 1
    loop {
        runtime.osyield()
        if t1_done != 0 return
    }
}

fn test_gc_basic_osyield() {
    fmt.println("test_gc_basic_osyield")
    t1_ready = 0
    t1_done = 0
    i<i32> = 0
    while i < 4 {
        runtime.newcore(worker_osyield.(u64))
        i += 1
    }
    spins<i32> = 0
    while t1_ready < 4 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("workers never ready")
    }
    runtime.GC()
    t1_done = 1
    time.sleep(1)
    fmt.println("test_gc_basic_osyield passed")
}

// ---- Test 2: multiple GC rounds with osyield workers ----

t2_ready<i32> = 0
t2_done<i32> = 0

fn worker_osyield2() {
    t2_ready = t2_ready + 1
    loop {
        runtime.osyield()
        if t2_done != 0 return
    }
}

fn test_gc_multi_round() {
    fmt.println("test_gc_multi_round")
    t2_ready = 0
    t2_done = 0
    i<i32> = 0
    while i < 4 {
        runtime.newcore(worker_osyield2.(u64))
        i += 1
    }
    spins<i32> = 0
    while t2_ready < 4 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("workers never ready")
    }
    // Multiple consecutive GC rounds.
    round<i32> = 0
    while round < 5 {
        runtime.GC()
        round += 1
    }
    t2_done = 1
    time.sleep(1)
    fmt.println("test_gc_multi_round passed")
}

// ---- Test 3: MutexInter contention + GC ----
// Workers hold runtime mutex while main forces GC; validates osyield
// skips STW when locks > 0.

mtx_lock<runtime.MutexInter:>
t3_ready<i32> = 0
t3_done<i32> = 0
t3_sum<i32> = 0

fn worker_mutex_loop() {
    t3_ready = t3_ready + 1
    n<i32> = 0
    while t3_done == 0 {
        mtx_lock.lock()
        t3_sum = t3_sum + 1
        mtx_lock.unlock()
        n += 1
        // Yield to participate in GC STW.
        runtime.osyield()
    }
}

fn test_gc_mutex_contention() {
    fmt.println("test_gc_mutex_contention")
    mtx_lock.init()
    t3_ready = 0
    t3_done = 0
    t3_sum = 0
    i<i32> = 0
    while i < 4 {
        runtime.newcore(worker_mutex_loop.(u64))
        i += 1
    }
    spins<i32> = 0
    while t3_ready < 4 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("mutex workers never ready")
    }
    time.sleep(1)
    runtime.GC()
    runtime.GC()
    t3_done = 1
    time.sleep(1)
    if t3_sum < 4 os.dief("mutex sum too low: %d", t3_sum)
    fmt.println("test_gc_mutex_contention passed")
}

// ---- Test 4: workers exit then second GC ----

t4_ready<i32> = 0
t4_round<i32> = 0

fn worker_exit_after_gc() {
    t4_ready = t4_ready + 1
    while t4_round == 0 {
        runtime.osyield()
    }
}

fn test_gc_worker_exit() {
    fmt.println("test_gc_worker_exit")
    t4_ready = 0
    t4_round = 0
    i<i32> = 0
    while i < 2 {
        runtime.newcore(worker_exit_after_gc.(u64))
        i += 1
    }
    spins<i32> = 0
    while t4_ready < 2 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("t4 workers never ready")
    }
    runtime.GC()
    t4_round = 1
    time.sleep(1)
    // Second GC after workers exited.
    runtime.GC()
    fmt.println("test_gc_worker_exit passed")
}

// ---- Test 5: heap alloc on main + osyield workers ----
// Main allocates heavily (may trigger GC internally); workers only osyield.

t5_ready<i32> = 0
t5_done<i32> = 0

fn worker_osyield5() {
    t5_ready = t5_ready + 1
    while t5_done == 0 {
        runtime.osyield()
    }
}

fn test_gc_heap_pressure() {
    fmt.println("test_gc_heap_pressure")
    t5_ready = 0
    t5_done = 0
    i<i32> = 0
    while i < 4 {
        runtime.newcore(worker_osyield5.(u64))
        i += 1
    }
    spins<i32> = 0
    while t5_ready < 4 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("t5 workers never ready")
    }
    // Allocate enough to trigger automatic GC.
    n<i32> = 0
    while n < 64 {
        p<u64> = runtime.malloc(65536, 0.(i8), 0.(i8))
        if p == 0 os.die("heap malloc failed")
        n += 1
    }
    t5_done = 1
    time.sleep(1)
    fmt.println("test_gc_heap_pressure passed")
}

fn main() {
    test_gc_basic_osyield()
    test_gc_multi_round()
    test_gc_mutex_contention()
    test_gc_worker_exit()
    test_gc_heap_pressure()
    fmt.println("all gc_mt tests passed")
}
