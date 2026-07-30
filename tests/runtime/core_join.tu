// CLEARTID join for newcore: wait until OS threads have fully exited.
// Replaces tight spin-wait which SEGV'd under concurrent thread teardown.
// Coverage: zero bits, single/many, already-exited, block-until-exit,
// double join, reverse order, serial cycles, legacy counter, GC+osyield.

use fmt
use os
use runtime
use std.atomic

DONE_CNT<i32> = 0
HOLD_FLAG<i32> = 0
LEGACY_ENTERED<i32> = 0

fn spin_until(target<i32>) {
    spins<i32> = 0
    while DONE_CNT < target {
        runtime.osyield()
        spins += 1
        if spins > 5000000 {
            os.die("workers never reached target count")
        }
    }
}

fn worker_quick_exit() {
    atomic.xadd(&DONE_CNT, 1.(u32))
}

fn worker_busy_exit() {
    n<i32> = 0
    while n < 2000000 {
        n += 1
    }
    atomic.xadd(&DONE_CNT, 1.(u32))
}

fn worker_hold_then_exit() {
    while HOLD_FLAG != 0 {
        runtime.osyield()
    }
    atomic.xadd(&DONE_CNT, 1.(u32))
}

fn worker_legacy_tracked() {
    runtime.core_join_inc()
    atomic.xadd(&LEGACY_ENTERED, 1.(u32))
    atomic.xadd(&DONE_CNT, 1.(u32))
}

fn worker_osyield_until_hold_clear() {
    atomic.xadd(&DONE_CNT, 1.(u32))
    while HOLD_FLAG != 0 {
        runtime.osyield()
    }
}

// core_join(0) is a no-op.
fn test_core_join_zero_bits() {
    fmt.println("test_core_join_zero_bits")
    runtime.core_join(0)
    fmt.println("test_core_join_zero_bits passed")
}

// One worker: spawn then join (no pre-wait; join must see exit).
fn test_core_join_single() {
    fmt.println("test_core_join_single")
    DONE_CNT = 0
    c0<u64> = runtime.newcore(worker_quick_exit.(u64))
    runtime.core_join(c0)
    if DONE_CNT != 1 {
        os.die("single DONE_CNT bad")
    }
    fmt.println("test_core_join_single passed")
}

// Four workers quick exit then join (baseline stress unit).
fn test_core_join_quick_exit() {
    fmt.println("test_core_join_quick_exit")
    DONE_CNT = 0
    c0<u64> = runtime.newcore(worker_quick_exit.(u64))
    c1<u64> = runtime.newcore(worker_quick_exit.(u64))
    c2<u64> = runtime.newcore(worker_quick_exit.(u64))
    c3<u64> = runtime.newcore(worker_quick_exit.(u64))
    spin_until(4)
    runtime.core_join(c0)
    runtime.core_join(c1)
    runtime.core_join(c2)
    runtime.core_join(c3)
    fmt.println("test_core_join_quick_exit passed")
}

// Join after workers already exited (clear_tid already 0 → immediate return).
fn test_core_join_already_exited() {
    fmt.println("test_core_join_already_exited")
    DONE_CNT = 0
    c0<u64> = runtime.newcore(worker_quick_exit.(u64))
    c1<u64> = runtime.newcore(worker_quick_exit.(u64))
    spin_until(2)
    // Extra yields so CLEARTID has time to zero the word before join.
    extra<i32> = 0
    while extra < 1000 {
        runtime.osyield()
        extra += 1
    }
    runtime.core_join(c0)
    runtime.core_join(c1)
    fmt.println("test_core_join_already_exited passed")
}

// Join without waiting on DONE first: must block until OS thread exit.
fn test_core_join_blocks_until_exit() {
    fmt.println("test_core_join_blocks_until_exit")
    DONE_CNT = 0
    c0<u64> = runtime.newcore(worker_busy_exit.(u64))
    runtime.core_join(c0)
    if DONE_CNT != 1 {
        os.die("join returned before worker finished")
    }
    fmt.println("test_core_join_blocks_until_exit passed")
}

// Join immediately after newcore (SETTID/CLEARTID race window).
fn test_core_join_immediate_after_spawn() {
    fmt.println("test_core_join_immediate_after_spawn")
    DONE_CNT = 0
    c0<u64> = runtime.newcore(worker_quick_exit.(u64))
    runtime.core_join(c0)
    if DONE_CNT != 1 {
        os.die("immediate join DONE_CNT bad")
    }
    fmt.println("test_core_join_immediate_after_spawn passed")
}

// Second join on the same Core after exit must return immediately.
fn test_core_join_double() {
    fmt.println("test_core_join_double")
    DONE_CNT = 0
    c0<u64> = runtime.newcore(worker_quick_exit.(u64))
    runtime.core_join(c0)
    runtime.core_join(c0)
    if DONE_CNT != 1 {
        os.die("double join DONE_CNT bad")
    }
    fmt.println("test_core_join_double passed")
}

// Join in reverse spawn order.
fn test_core_join_reverse_order() {
    fmt.println("test_core_join_reverse_order")
    DONE_CNT = 0
    c0<u64> = runtime.newcore(worker_quick_exit.(u64))
    c1<u64> = runtime.newcore(worker_quick_exit.(u64))
    c2<u64> = runtime.newcore(worker_quick_exit.(u64))
    c3<u64> = runtime.newcore(worker_quick_exit.(u64))
    runtime.core_join(c3)
    runtime.core_join(c2)
    runtime.core_join(c1)
    runtime.core_join(c0)
    if DONE_CNT != 4 {
        os.die("reverse DONE_CNT bad")
    }
    fmt.println("test_core_join_reverse_order passed")
}

// Many workers.
fn test_core_join_many() {
    fmt.println("test_core_join_many")
    DONE_CNT = 0
    n<i32> = 16
    cores<u64*> = runtime.malloc(8 * n.(u64), 0.(i8), 1.(i8))
    i<i32> = 0
    while i < n {
        cores[i] = runtime.newcore(worker_quick_exit.(u64))
        i += 1
    }
    j<i32> = 0
    while j < n {
        runtime.core_join(cores[j])
        j += 1
    }
    if DONE_CNT != n {
        os.die("many DONE_CNT bad")
    }
    fmt.println("test_core_join_many passed")
}

// Serial spawn+join cycles on one OS thread (caller).
fn test_core_join_serial_cycles() {
    fmt.println("test_core_join_serial_cycles")
    round<i32> = 0
    while round < 32 {
        DONE_CNT = 0
        c0<u64> = runtime.newcore(worker_quick_exit.(u64))
        runtime.core_join(c0)
        if DONE_CNT != 1 {
            os.die("serial cycle DONE_CNT bad")
        }
        round += 1
    }
    fmt.println("test_core_join_serial_cycles passed")
}

// Hold workers alive, then release and join (join observes CLEARTID wake).
fn test_core_join_after_release() {
    fmt.println("test_core_join_after_release")
    DONE_CNT = 0
    HOLD_FLAG = 1
    c0<u64> = runtime.newcore(worker_hold_then_exit.(u64))
    c1<u64> = runtime.newcore(worker_hold_then_exit.(u64))
    // Wait until both are spinning in the hold loop (DONE still 0).
    warm<i32> = 0
    while warm < 10000 {
        runtime.osyield()
        warm += 1
    }
    if DONE_CNT != 0 {
        os.die("hold workers exited early")
    }
    HOLD_FLAG = 0
    runtime.core_join(c0)
    runtime.core_join(c1)
    if DONE_CNT != 2 {
        os.die("after release DONE_CNT bad")
    }
    fmt.println("test_core_join_after_release passed")
}

// Legacy core_join_inc / core_join_count still decrements by thread exit.
fn test_core_join_legacy_counter() {
    fmt.println("test_core_join_legacy_counter")
    runtime.core_join_reset()
    DONE_CNT = 0
    LEGACY_ENTERED = 0
    c0<u64> = runtime.newcore(worker_legacy_tracked.(u64))
    c1<u64> = runtime.newcore(worker_legacy_tracked.(u64))
    spin_until(2)
    if LEGACY_ENTERED != 2 {
        os.die("legacy entered bad")
    }
    runtime.core_join(c0)
    runtime.core_join(c1)
    spins2<i32> = 0
    while runtime.core_join_count() != 0 {
        runtime.osyield()
        spins2 += 1
        if spins2 > 5000000 {
            os.die("legacy count never reached 0")
        }
    }
    fmt.println("test_core_join_legacy_counter passed")
}

// Workers osyield through GC STW, then join (no sleep-based teardown).
fn test_core_join_with_gc() {
    fmt.println("test_core_join_with_gc")
    DONE_CNT = 0
    HOLD_FLAG = 1
    c0<u64> = runtime.newcore(worker_osyield_until_hold_clear.(u64))
    c1<u64> = runtime.newcore(worker_osyield_until_hold_clear.(u64))
    c2<u64> = runtime.newcore(worker_osyield_until_hold_clear.(u64))
    c3<u64> = runtime.newcore(worker_osyield_until_hold_clear.(u64))
    spin_until(4)
    runtime.GC()
    HOLD_FLAG = 0
    runtime.core_join(c0)
    runtime.core_join(c1)
    runtime.core_join(c2)
    runtime.core_join(c3)
    fmt.println("test_core_join_with_gc passed")
}

fn run_all_once() {
    test_core_join_zero_bits()
    test_core_join_single()
    test_core_join_quick_exit()
    test_core_join_already_exited()
    test_core_join_blocks_until_exit()
    test_core_join_immediate_after_spawn()
    test_core_join_double()
    test_core_join_reverse_order()
    test_core_join_many()
    test_core_join_serial_cycles()
    test_core_join_after_release()
    test_core_join_legacy_counter()
    test_core_join_with_gc()
}

fn main() {
    run_all_once()
    // Repeat the race-sensitive subset under load.
    round<i32> = 0
    while round < 30 {
        test_core_join_quick_exit()
        test_core_join_immediate_after_spawn()
        test_core_join_double()
        test_core_join_blocks_until_exit()
        round += 1
    }
    fmt.println("core_join all passed")
}
