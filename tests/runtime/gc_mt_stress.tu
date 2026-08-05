// GC STW correctness with newcore OS threads.
// Validates osyield checking gcwaiting + locks/mallocing guards.
// Every worker is core_join'd so fire-and-forget cores cannot poison later STW.

use fmt
use os
use runtime

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
    c0<u64> = runtime.newcore(worker_osyield.(u64))
    c1<u64> = runtime.newcore(worker_osyield.(u64))
    c2<u64> = runtime.newcore(worker_osyield.(u64))
    c3<u64> = runtime.newcore(worker_osyield.(u64))
    spins<i32> = 0
    while t1_ready < 4 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("workers never ready")
    }
    runtime.GC()
    t1_done = 1
    runtime.core_join(c0)
    runtime.core_join(c1)
    runtime.core_join(c2)
    runtime.core_join(c3)
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
    c0<u64> = runtime.newcore(worker_osyield2.(u64))
    c1<u64> = runtime.newcore(worker_osyield2.(u64))
    c2<u64> = runtime.newcore(worker_osyield2.(u64))
    c3<u64> = runtime.newcore(worker_osyield2.(u64))
    spins<i32> = 0
    while t2_ready < 4 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("workers never ready")
    }
    round<i32> = 0
    while round < 5 {
        runtime.GC()
        // Let workers re-enter osyield between rounds (avoid STW edge races).
        y<i32> = 0
        while y < 64 {
            runtime.osyield()
            y += 1
        }
        round += 1
    }
    t2_done = 1
    runtime.core_join(c0)
    runtime.core_join(c1)
    runtime.core_join(c2)
    runtime.core_join(c3)
    fmt.println("test_gc_multi_round passed")
}

// ---- Test 3: MutexInter contention + GC ----

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
        // Yield often so STW soft-syscall / Kick paths interleave with lock.
        if n % 8 == 0 {
            runtime.osyield()
        }
    }
}

fn test_gc_mutex_contention() {
    fmt.println("test_gc_mutex_contention")
    mtx_lock.init()
    t3_ready = 0
    t3_done = 0
    t3_sum = 0
    c0<u64> = runtime.newcore(worker_mutex_loop.(u64))
    c1<u64> = runtime.newcore(worker_mutex_loop.(u64))
    c2<u64> = runtime.newcore(worker_mutex_loop.(u64))
    c3<u64> = runtime.newcore(worker_mutex_loop.(u64))
    spins<i32> = 0
    while t3_ready < 4 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("mutex workers never ready")
    }
    // GC while workers contend MutexInter (futex waiters with locks>0).
    // Soft-syscall + startSTW must leave CoreSyscall alone across rounds.
// startSTW also tolerates CoreRun after clearing gcwaiting (exitsyscall race);
// dief there used to exit only one thread and wedge MT httpserver.
    round<i32> = 0
    while round < 40 {
        runtime.GC()
        y<i32> = 0
        while y < 16 {
            runtime.osyield()
            y += 1
        }
        round += 1
    }
    t3_done = 1
    runtime.core_join(c0)
    runtime.core_join(c1)
    runtime.core_join(c2)
    runtime.core_join(c3)
    if t3_sum < 4 os.dief("mutex sum too low: %d", t3_sum)
    runtime.GC()
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
    c0<u64> = runtime.newcore(worker_exit_after_gc.(u64))
    c1<u64> = runtime.newcore(worker_exit_after_gc.(u64))
    spins<i32> = 0
    while t4_ready < 2 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("t4 workers never ready")
    }
    runtime.GC()
    t4_round = 1
    runtime.core_join(c0)
    runtime.core_join(c1)
    // Second GC after workers fully joined/exited.
    runtime.GC()
    fmt.println("test_gc_worker_exit passed")
}

// ---- Test 5: heap alloc on main + osyield workers ----

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
    c0<u64> = runtime.newcore(worker_osyield5.(u64))
    c1<u64> = runtime.newcore(worker_osyield5.(u64))
    c2<u64> = runtime.newcore(worker_osyield5.(u64))
    c3<u64> = runtime.newcore(worker_osyield5.(u64))
    spins<i32> = 0
    while t5_ready < 4 {
        runtime.osyield()
        spins += 1
        if spins > 5000000 os.die("t5 workers never ready")
    }
    n<i32> = 0
    while n < 64 {
        p<u64> = runtime.malloc(65536, 0.(i8), 0.(i8))
        if p == 0 os.die("heap malloc failed")
        n += 1
    }
    t5_done = 1
    runtime.core_join(c0)
    runtime.core_join(c1)
    runtime.core_join(c2)
    runtime.core_join(c3)
    fmt.println("test_gc_heap_pressure passed")
}

// ---- Test 6: GC while workers are exiting (rmcore vs stopSTW race) ----

t6_ready<i32> = 0

fn worker_quick_ready_exit() {
    t6_ready = t6_ready + 1
    // Return immediately so corestart hits schedule/rmcore while main GCs.
}

fn test_gc_exit_during_stw() {
    fmt.println("test_gc_exit_during_stw")
    round<i32> = 0
    while round < 20 {
        t6_ready = 0
        c0<u64> = runtime.newcore(worker_quick_ready_exit.(u64))
        c1<u64> = runtime.newcore(worker_quick_ready_exit.(u64))
        c2<u64> = runtime.newcore(worker_quick_ready_exit.(u64))
        c3<u64> = runtime.newcore(worker_quick_ready_exit.(u64))
        spins<i32> = 0
        while t6_ready < 4 {
            runtime.osyield()
            spins += 1
            if spins > 5000000 os.die("t6 workers never ready")
        }
        // Workers are exiting (or gone); STW must not sleep forever.
        runtime.GC()
        runtime.core_join(c0)
        runtime.core_join(c1)
        runtime.core_join(c2)
        runtime.core_join(c3)
        round += 1
    }
    fmt.println("test_gc_exit_during_stw passed")
}

fn main() {
    test_gc_basic_osyield()
    test_gc_multi_round()
    test_gc_mutex_contention()
    test_gc_worker_exit()
    test_gc_heap_pressure()
    test_gc_exit_during_stw()
    fmt.println("all gc_mt tests passed")
}
