// Read-only hang diagnostics for multi_thread scheduler.
// Prints idle packed counts, sleeper depth, inject depth, per-worker park state,
// schedule/notify hit-miss counters, and OwnedTasks with queue-location tags.

use fmt
use runtime
use os
use std
use string
use std.atomic
use sys
use asyncio.task
use asyncio.runtime.io as rtio

// Process-wide counters (debug only).
MT_SCHED_LOCAL<i32> = 0
MT_SCHED_REMOTE<i32> = 0
MT_NOTIFY_HIT<i32> = 0
MT_NOTIFY_MISS<i32> = 0

fn mt_sched_count_local() {
    atomic.xadd(&MT_SCHED_LOCAL, 1)
}

fn mt_sched_count_remote() {
    atomic.xadd(&MT_SCHED_REMOTE, 1)
}

fn mt_notify_count_hit() {
    atomic.xadd(&MT_NOTIFY_HIT, 1)
}

fn mt_notify_count_miss() {
    atomic.xadd(&MT_NOTIFY_MISS, 1)
}

// Hang-watchdog arming (set from tests /tmp probes). Dump runs on park threads.
MT_HANG_DUMP_MH<u64> = 0
MT_HANG_DUMP_IOH<u64> = 0
MT_HANG_DUMP_REQ<i32> = 0
// Soft: print dump and continue (no os.exit). Used for ab miss forensics.
MT_HANG_DUMP_SOFT<i32> = 0
MT_HANG_DUMP_FILE_POLL<i32> = 0

fn mt_hang_dump_arm(mh_bits<u64>, ioh_bits<u64>) {
    MT_HANG_DUMP_MH = mh_bits
    MT_HANG_DUMP_IOH = ioh_bits
}

fn mt_hang_dump_set_soft(v<i32>) {
    MT_HANG_DUMP_SOFT = v
}

fn mt_hang_dump_enable_file_poll(v<i32>) {
    MT_HANG_DUMP_FILE_POLL = v
}

fn mt_hang_dump_request() {
    MT_HANG_DUMP_REQ = 1
}

// Force dump on the calling thread (watchdog OS thread). Prefer this when
// workers are stuck in epoll/futex and never re-enter wait_until_wake.
fn mt_hang_dump_now() {
    MT_HANG_DUMP_REQ = 1
    mt_hang_dump_maybe()
}

fn mt_hang_dump_cancel() {
    MT_HANG_DUMP_REQ = 0
}

// External trigger: ab script touches /tmp/mt_dump.req after a miss.
fn mt_hang_dump_poll_file() {
    if MT_HANG_DUMP_FILE_POLL == 0 {
        return
    }
    if MT_HANG_DUMP_MH == 0 {
        return
    }
    path<string.String> = string.S(*"/tmp/mt_dump.req")
    pc<i8*> = path.str()
    fd<i32> = sys.openat(std.AT_FDCWD, pc, 0.(i64), 0.(i64))
    if fd < 0 {
        return
    }
    sys.close(fd)
    sys.unlink(pc)
    MT_HANG_DUMP_REQ = 1
}

// Called from park paths (worker / block_on) so we stay on a runtime thread.
// Keep this body minimal — large helper calls have hit "call not func object".
fn mt_hang_dump_maybe() {
    mt_hang_dump_poll_file()
    if MT_HANG_DUMP_REQ == 0 {
        return
    }
    MT_HANG_DUMP_REQ = 0
    fmt.println("=== HANG WATCHDOG DUMP ===")
    bits<u64> = MT_HANG_DUMP_MH
    if bits == 0 {
        fmt.println("mt_hang: null mh")
        if MT_HANG_DUMP_SOFT == 0 {
            os.exit(42)
        }
        return
    }
    mh<MtHandle> = bits.(MtHandle)
    shared<MtShared> = mh.shared
    if shared == null {
        fmt.println("mt_hang: null shared")
        if MT_HANG_DUMP_SOFT == 0 {
            os.exit(42)
        }
        return
    }
    cur<i32> = 0
    if shared.idle != null {
        cur = shared.idle.state
    }
    unparked<u32> = (cur.(u32) >> 16) & 0xFFFF
    searching<u32> = cur.(u32) & 0xFFFF
    sleepers<u32> = 0
    sn<MtSynced> = shared.lock_hub
    if sn != null && sn.idle_synced != null {
        sleepers = sn.idle_synced.sleepers_len
    }
    fmt.println("mt_hang: workers=", int(shared.num_workers),
        " unparked=", int(unparked),
        " searching=", int(searching),
        " sleepers=", int(sleepers),
        " shutting=", int(shared.shutting_down))
    fmt.println("mt_hang: notify_hit=", int(MT_NOTIFY_HIT),
        " notify_miss=", int(MT_NOTIFY_MISS),
        " sched_local=", int(MT_SCHED_LOCAL),
        " sched_remote=", int(MT_SCHED_REMOTE))
    inj_d<u32> = 0
    if shared.inject != null && shared.inject.depth_atomic != null {
        inj_d = shared.inject.depth_atomic.depth
    }
    fmt.println("mt_hang: inject_depth=", int(inj_d))
    fmt.println("mt_hang: wake_submit=", int(task.io_wake_submit_get()),
        " wake_nop=", int(task.io_wake_nop_get()),
        " wake_zero=", int(task.io_wake_zero_get()),
        " wake_tag=", int(task.io_wake_tag_get()),
        " wake_dealloc=", int(task.io_wake_dealloc_get()))

    search_local_sum<i32> = 0
    i<u32> = 0
    while i < shared.num_workers {
        rb<u64> = shared.remotes[i]
        if rb == 0 {
            fmt.println("  remote[", int(i), "] null")
            i += 1
            continue
        }
        r<Remote> = rb.(Remote)
        pst<i32> = -1
        if r.unparker != null && r.unparker.owner != null {
            pst = r.unparker.owner.state.(i32)
        }
        is_s<i32> = 0
        lifo_nz<i32> = 0
        prog<u64> = 0
        if r.core_bits != 0 {
            core<WorkerCore> = r.core_bits.(WorkerCore)
            is_s = core.is_searching
            search_local_sum += is_s
            prog = core.progress
            if core.lifo_slot != 0 {
                lifo_nz = 1
            }
        }
        steal_empty<i32> = 1
        if r.steal_end != null {
            steal_empty = r.steal_end.is_empty()
        }
        fmt.println("  remote[", int(i), "] park=", int(pst),
            " is_searching=", int(is_s),
            " lifo=", int(lifo_nz),
            " steal_empty=", int(steal_empty),
            " progress=", int(prog))
        i += 1
    }
    if searching > 0.(u32) && search_local_sum == 0 {
        fmt.println("mt_hang: SEARCHING_LEAK")
    }
    // Driver gate: 0=FREE 1=HELD. If HELD with no PARKED_DRIVER, gate leak.
    hub<ParkDriverHub> = shared.park_hub
    if hub != null {
        fmt.println("mt_hang: drv_gate=", int(hub.drv_gate),
            " time_on=", int(hub.time_on))
    } else {
        fmt.println("mt_hang: park_hub=null")
    }
    // IO registrations + waiter ctx (decisive for wake-lost vs searching).
    iohb<u64> = MT_HANG_DUMP_IOH
    if iohb != 0 {
        rtio.io_debug_dump(iohb)
    } else {
        fmt.println("io_debug: no ioh armed")
    }
    // Owned tasks snapshot (states only).
    owned<task.OwnedTasks> = shared.owned
    if owned != null {
        m<runtime.MutexInter> = owned.lock
        m.lock()
        fmt.println("mt_hang: owned_active=", int(owned.active))
        cur_raw<task.RawTask> = null
        if owned.head != 0 {
            cur_raw = owned.head.(task.RawTask)
        }
        n<i32> = 0
        while cur_raw != null && n < 32 {
            st<i32> = cur_raw.life_load()
            stage<i32> = -1
            if cur_raw.task_cell != null {
                stage = cur_raw.task_cell.load_stage()
            }
            fmt.println("  task[", int(n), "] ptr=", int(cur_raw.(u64)),
                " state=", int(st),
                " run=", int(st & 1),
                " done=", int((st >> 1) & 1),
                " ntf=", int((st >> 2) & 1),
                " join_w=", int((st >> 4) & 1),
                " ref=", int((st >> 6) & 0x3FFFFFF),
                " stage=", int(stage))
            nxt<task.RawTask> = null
            if cur_raw.task_header != null {
                nxt = cur_raw.task_header.owned_next_out()
            }
            cur_raw = nxt
            n += 1
        }
        m.unlock()
    }
    if sn != null && sn.idle_synced != null {
        shared.synced_lock.lock()
        si<u32> = 0
        while si < sn.idle_synced.sleepers_len && si < 8.(u32) {
            fmt.println("  sleeper[", int(si), "]=", int(sn.idle_synced.sleepers[si]))
            si += 1
        }
        shared.synced_lock.unlock()
    }
    if MT_HANG_DUMP_SOFT != 0 {
        fmt.println("=== END DUMP (soft) ===")
        return
    }
    // Second progress sample ~1s later: frozen workers keep the same count.
    fmt.println("mt_hang: progress sample-2 after 1s")
    runtime.entersyscall()
    req<std.TimeSpec:> = null
    rem<std.TimeSpec:> = null
    req.sec = 1
    req.nsec = 0
    std.nanosleep(&req, &rem)
    runtime.exitsyscall()
    i2<u32> = 0
    while i2 < shared.num_workers {
        rb2<u64> = shared.remotes[i2]
        if rb2 == 0 {
            i2 += 1
            continue
        }
        r2<Remote> = rb2.(Remote)
        prog2<u64> = 0
        if r2.core_bits != 0 {
            c2<WorkerCore> = r2.core_bits.(WorkerCore)
            prog2 = c2.progress
        }
        fmt.println("  remote[", int(i2), "] progress2=", int(prog2))
        i2 += 1
    }
    fmt.println("=== END DUMP ===")
    os.exit(42)
}

// True if `bits` appears in inject intrusive list (queue_next). Caller holds gate.
fn mt_bits_in_inject(inj<Inject>, bits<u64>) i32 {
    if inj == null || bits == 0 {
        return 0
    }
    sn<InjectSynced> = inj.fifo_state
    if sn == null {
        return 0
    }
    cur_bits<u64> = sn.head
    n<i32> = 0
    while cur_bits != 0 && n < 512 {
        if cur_bits == bits {
            return 1
        }
        rawt<task.RawTask> = cur_bits.(task.RawTask)
        if rawt == null || rawt.task_header == null {
            break
        }
        nxt<task.RawTask> = rawt.task_header.queue_next_out()
        if nxt == null {
            break
        }
        cur_bits = nxt.(u64)
        n += 1
    }
    return 0
}

// True if `bits` appears in a local/steal ring buffer (best-effort, no lock).
fn mt_bits_in_queue_hub(hub<QueueInner>, bits<u64>) i32 {
    if hub == null || hub.buffer == null || bits == 0 {
        return 0
    }
    i<u32> = 0
    while i < LOCAL_QUEUE_CAPACITY {
        if hub.buffer[i] == bits {
            return 1
        }
        i += 1
    }
    return 0
}

// Locate RawTask bits across inject / lifo / local rings. Returns tag string via prints.
fn mt_locate_task(shared<MtShared>, bits<u64>) {
    loc_inj<i32> = 0
    loc_lifo<i32> = -1
    loc_local<i32> = -1
    if shared.inject != null {
        shared.inject.gate_lock.lock()
        loc_inj = mt_bits_in_inject(shared.inject, bits)
        shared.inject.gate_lock.unlock()
    }
    wi<u32> = 0
    while wi < shared.num_workers {
        rb<u64> = shared.remotes[wi]
        if rb == 0 {
            wi += 1
            continue
        }
        r<Remote> = rb.(Remote)
        if r.core_bits != 0 {
            core<WorkerCore> = r.core_bits.(WorkerCore)
            if core.lifo_slot == bits {
                loc_lifo = wi.(i32)
            }
        }
        if r.steal_end != null && r.steal_end.queue_hub != null {
            if mt_bits_in_queue_hub(r.steal_end.queue_hub, bits) == 1 {
                loc_local = wi.(i32)
            }
        }
        wi += 1
    }
    fmt.println("    loc inj=", int(loc_inj),
        " lifo_w=", int(loc_lifo),
        " local_w=", int(loc_local))
}

// Decode Idle.state: [unparked:u16 << 16 | searching:u16].
// Also dumps OwnedTasks with bit flags + queue locations (hang forensics).
fn mt_debug_dump(bits<u64>) {
    if bits == 0 {
        fmt.println("mt_debug: null handle")
        return
    }
    mh<MtHandle> = bits.(MtHandle)
    shared<MtShared> = mh.shared
    if shared == null {
        fmt.println("mt_debug: null shared")
        return
    }
    idle<Idle> = shared.idle
    cur<i32> = 0
    if idle != null {
        cur = idle.state
    }
    unparked<u32> = (cur.(u32) >> 16) & 0xFFFF
    searching<u32> = cur.(u32) & 0xFFFF
    sleepers<u32> = 0
    sn<MtSynced> = shared.lock_hub
    if sn != null && sn.idle_synced != null {
        sleepers = sn.idle_synced.sleepers_len
    }
    inj_depth<u32> = 0
    if shared.inject != null && shared.inject.depth_atomic != null {
        inj_depth = atomic.load(&shared.inject.depth_atomic.depth).(u32)
    }
    alive_n<i32> = shared.workers_alive
    fmt.println("mt_debug: workers=", int(shared.num_workers),
        " unparked=", int(unparked),
        " searching=", int(searching),
        " sleepers=", int(sleepers),
        " inject=", int(inj_depth),
        " shutting=", int(shared.shutting_down),
        " alive=", int(alive_n))
    fmt.println("mt_debug: sched_local=", int(MT_SCHED_LOCAL),
        " sched_remote=", int(MT_SCHED_REMOTE),
        " notify_hit=", int(MT_NOTIFY_HIT),
        " notify_miss=", int(MT_NOTIFY_MISS))

    // Detect searching leak: idle searching>0 but no worker is_searching.
    search_local_sum<i32> = 0
    si0<u32> = 0
    while si0 < shared.num_workers {
        rb0<u64> = shared.remotes[si0]
        if rb0 != 0 {
            r0<Remote> = rb0.(Remote)
            if r0.core_bits != 0 {
                c0<WorkerCore> = r0.core_bits.(WorkerCore)
                search_local_sum += c0.is_searching
            }
        }
        si0 += 1
    }
    if searching > 0.(u32) && search_local_sum == 0 {
        fmt.println("mt_debug: SEARCHING_LEAK idle_searching=", int(searching),
            " local_sum=", int(search_local_sum))
    }
    if sn != null && sn.idle_synced != null {
        shared.synced_lock.lock()
        si<u32> = 0
        while si < sn.idle_synced.sleepers_len {
            fmt.println("  sleeper[", int(si), "]=", int(sn.idle_synced.sleepers[si]))
            si += 1
        }
        shared.synced_lock.unlock()
    }

    i<u32> = 0
    while i < shared.num_workers {
        rb<u64> = shared.remotes[i]
        if rb == 0 {
            fmt.println("  remote[", int(i), "] null")
            i += 1
            continue
        }
        r<Remote> = rb.(Remote)
        pst<i32> = -1
        if r.unparker != null && r.unparker.owner != null {
            pst = r.unparker.owner.state.(i32)
        }
        steal_empty<i32> = 1
        if r.steal_end != null {
            steal_empty = r.steal_end.is_empty()
        }
        searching_local<i32> = -1
        lifo_nz<i32> = 0
        if r.core_bits != 0 {
            core<WorkerCore> = r.core_bits.(WorkerCore)
            searching_local = core.is_searching
            if core.lifo_slot != 0 {
                lifo_nz = 1
            }
        }
        fmt.println("  remote[", int(i), "] park_state=", int(pst),
            " steal_empty=", int(steal_empty),
            " is_searching=", int(searching_local),
            " lifo=", int(lifo_nz))
        i += 1
    }
    if shared.block_on_unparker != null && shared.block_on_unparker.owner != null {
        bst<i32> = shared.block_on_unparker.owner.state.(i32)
        fmt.println("  block_on park_state=", int(bst))
    }
    owned<task.OwnedTasks> = shared.owned
    if owned != null {
        m<runtime.MutexInter> = owned.lock
        m.lock()
        fmt.println("mt_debug: owned_active=", int(owned.active))
        // Snapshot (bits, state) under lock — do not life_load after unlock (UAF).
        snap_bits<u64*> = runtime.malloc(8 * 64.(u64), 0.(i8), 1.(i8))
        snap_st<i32*> = runtime.malloc(4 * 64.(u64), 1.(i8), 1.(i8))
        snap_n<i32> = 0
        cur_raw<task.RawTask> = null
        if owned.head != 0 {
            cur_raw = owned.head.(task.RawTask)
        }
        while cur_raw != null && snap_n < 64 {
            snap_bits[snap_n] = cur_raw.(u64)
            snap_st[snap_n] = cur_raw.life_load()
            nxt<task.RawTask> = null
            if cur_raw.task_header != null {
                nxt = cur_raw.task_header.owned_next_out()
            }
            cur_raw = nxt
            snap_n += 1
        }
        m.unlock()

        n<i32> = 0
        while n < snap_n {
            tb<u64> = snap_bits[n]
            st<i32> = snap_st[n]
            fmt.println("  task[", int(n), "] bits=", int(tb),
                " state=", int(st),
                " run=", int(st & 1),
                " done=", int((st >> 1) & 1),
                " ntf=", int((st >> 2) & 1),
                " join_i=", int((st >> 3) & 1),
                " join_w=", int((st >> 4) & 1),
                " cancel=", int((st >> 5) & 1),
                " ref=", int((st >> 6) & 0x3FFFFFF))
            // Locate only when not COMPLETE — completed tasks leave queues.
            if (st & 2) == 0 {
                mt_locate_task(shared, tb)
            }
            n += 1
        }
    }
}
