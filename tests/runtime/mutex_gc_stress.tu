// Runtime redline: holding MutexInter must not start STW from malloc.
// Covers lock-held alloc, contended unlock paths, and GC after unlock.

use fmt
use os
use runtime

g_lock<runtime.MutexInter> = null
g_ready<i32> = 0
g_done<i32> = 0
g_counter<i32> = 0

fn ensure_lock() {
    if g_lock != null return
    g_lock = new runtime.MutexInter
    g_lock.init()
}

fn worker_lock_alloc() {
    ensure_lock()
    g_ready = g_ready + 1
    loop {
        if g_done != 0 return
        g_lock.lock()
        // Alloc while holding the lock — must not call gc.start on this core.
        p<u64*> = runtime.malloc(64.(u64), 1.(i8), 1.(i8))
        if p == null {
            g_lock.unlock()
            os.die("malloc null under lock")
        }
        g_counter = g_counter + 1
        g_lock.unlock()
        // Yield so STW can stop this core between critical sections.
        runtime.osyield()
        runtime.osyield()
    }
}

fn wait_ready(need<i32>) {
    spins<i32> = 0
    while g_ready < need {
        runtime.osyield()
        spins += 1
        if spins > 5000000 {
            os.die("workers never ready")
        }
    }
}

fn join4(c0<u64>, c1<u64>, c2<u64>, c3<u64>) {
    runtime.core_join(c0)
    runtime.core_join(c1)
    runtime.core_join(c2)
    runtime.core_join(c3)
}

// Single core: many lock-held allocs (large enough to set shouldgc), then GC.
fn test_lock_alloc_defer_gc() {
    fmt.println("test_lock_alloc_defer_gc")
    ensure_lock()
    i<i32> = 0
    while i < 200 {
        g_lock.lock()
        // Large alloc forces shouldgc; with locks>0 must not start STW here.
        p<u64*> = runtime.malloc(8192.(u64), 1.(i8), 1.(i8))
        if p == null {
            g_lock.unlock()
            os.die("large malloc null")
        }
        g_lock.unlock()
        i += 1
    }
    runtime.GC()
    fmt.println("test_lock_alloc_defer_gc passed")
}

// Contended lock+alloc workers, GC only after they stop.
fn test_mutex_alloc_then_gc() {
    fmt.println("test_mutex_alloc_then_gc")
    ensure_lock()
    g_ready = 0
    g_done = 0
    g_counter = 0
    c0<u64> = runtime.newcore(worker_lock_alloc.(u64))
    c1<u64> = runtime.newcore(worker_lock_alloc.(u64))
    c2<u64> = runtime.newcore(worker_lock_alloc.(u64))
    c3<u64> = runtime.newcore(worker_lock_alloc.(u64))
    wait_ready(4)
    // Let workers run lock+alloc for a while without forcing STW mid-hold.
    spins<i32> = 0
    while spins < 200000 {
        runtime.osyield()
        spins += 1
        if g_counter > 1000 {
            break
        }
    }
    if g_counter <= 0 {
        g_done = 1
        join4(c0, c1, c2, c3)
        os.die("no lock progress")
    }
    g_done = 1
    join4(c0, c1, c2, c3)
    runtime.GC()
    fmt.println("test_mutex_alloc_then_gc passed")
}

// Serial spawn/join of lock+alloc workers (no mid-run forced GC).
fn test_lock_alloc_serial_cycles() {
    fmt.println("test_lock_alloc_serial_cycles")
    ensure_lock()
    n<i32> = 0
    while n < 8 {
        g_ready = 0
        g_done = 0
        g_counter = 0
        c0<u64> = runtime.newcore(worker_lock_alloc.(u64))
        c1<u64> = runtime.newcore(worker_lock_alloc.(u64))
        wait_ready(2)
        spins<i32> = 0
        while spins < 50000 {
            runtime.osyield()
            spins += 1
            if g_counter > 100 {
                break
            }
        }
        g_done = 1
        runtime.core_join(c0)
        runtime.core_join(c1)
        n += 1
    }
    runtime.GC()
    fmt.println("test_lock_alloc_serial_cycles passed")
}

fn main() {
    test_lock_alloc_defer_gc()
    test_mutex_alloc_then_gc()
    test_lock_alloc_serial_cycles()
    fmt.println("mutex_gc_stress all passed")
}
