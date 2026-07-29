// Per-OS-thread active RuntimeContext + bound WorkerCore bits.
// Mother with_current: while a worker holds the core, spawn may
// schedule_local via mt_core_current_bits → typed WorkerCore.
// Wake/Schedule stays inject — casting WorkerCore inside api Schedule
// still SEGV's under load (optimize 2026-07-29e/j).
// cores[] is runtime.malloc(noscan=0) so WorkerCore* bits stay GC roots.

use runtime
use std

CTX_TID_CAP<i32> = 64

mem CtxTlsHub {
    runtime.MutexInter* lock
    u64* tids
    u64* ctxs
    u64* cores              // WorkerCore* bits while worker holds the core
}

CTX_HUB<CtxTlsHub> = null

// Layout matches asyncio.runtime.RtSavedSlot (cross-package bitcast).
mem MtCtxSaved {
    u64 prev_bits
    i64 tid
    i32 slot_idx
}

fn ctx_hub_ensure() {
    if CTX_HUB != null {
        return
    }
    h<CtxTlsHub> = new CtxTlsHub
    h.lock = new runtime.MutexInter
    h.lock.init()
    n<u64> = CTX_TID_CAP.(u64)
    // noscan=0: ctxs/cores hold heap pointer bits that must be scanned.
    h.tids = runtime.malloc(8 * n, 0.(i8), 1.(i8))
    h.ctxs = runtime.malloc(8 * n, 0.(i8), 1.(i8))
    h.cores = runtime.malloc(8 * n, 0.(i8), 1.(i8))
    i<i32> = 0
    while i < CTX_TID_CAP {
        h.tids[i] = 0
        h.ctxs[i] = 0
        h.cores[i] = 0
        i += 1
    }
    CTX_HUB = h
}

// Builder calls this before spawning worker OS threads so workers never
// race on lazy hub creation.
fn mt_ctx_hub_init() {
    ctx_hub_ensure()
}

fn ctx_tid_find(h<CtxTlsHub>, tid<u64>) i32 {
    i<i32> = 0
    while i < CTX_TID_CAP {
        if h.tids[i] == tid {
            return i
        }
        i += 1
    }
    return -1
}

fn ctx_tid_claim(h<CtxTlsHub>, tid<u64>) i32 {
    found<i32> = ctx_tid_find(h, tid)
    if found >= 0 {
        return found
    }
    j<i32> = 0
    while j < CTX_TID_CAP {
        if h.tids[j] == 0 {
            h.tids[j] = tid
            h.ctxs[j] = 0
            h.cores[j] = 0
            return j
        }
        j += 1
    }
    h.tids[0] = tid
    h.cores[0] = 0
    return 0
}

// Saved slot layout matches asyncio.runtime.RtSavedSlot (u64 prev_bits).
fn mt_ctx_enter(ctx_bits<u64>) u64 {
    ctx_hub_ensure()
    h<CtxTlsHub> = CTX_HUB
    tid<u64> = std.gettid()
    h.lock.lock()
    idx<i32> = ctx_tid_claim(h, tid)
    saved<MtCtxSaved> = new MtCtxSaved
    saved.prev_bits = h.ctxs[idx]
    saved.tid = tid.(i64)
    saved.slot_idx = idx
    h.ctxs[idx] = ctx_bits
    h.lock.unlock()
    return saved.(u64)
}

fn mt_ctx_exit(saved_bits<u64>) {
    if saved_bits == 0 {
        return
    }
    ctx_hub_ensure()
    h<CtxTlsHub> = CTX_HUB
    saved<MtCtxSaved> = saved_bits.(MtCtxSaved)
    h.lock.lock()
    idx<i32> = saved.slot_idx
    if idx >= 0 && idx < CTX_TID_CAP {
        h.cores[idx] = 0
        if saved.prev_bits == 0 {
            h.ctxs[idx] = 0
            h.tids[idx] = 0
        } else {
            h.ctxs[idx] = saved.prev_bits
        }
    }
    h.lock.unlock()
}

fn mt_ctx_current_bits() u64 {
    ctx_hub_ensure()
    h<CtxTlsHub> = CTX_HUB
    tid<u64> = std.gettid()
    h.lock.lock()
    idx<i32> = ctx_tid_find(h, tid)
    out<u64> = 0
    if idx >= 0 {
        out = h.ctxs[idx]
    }
    h.lock.unlock()
    return out
}

// Bind the WorkerCore this OS thread currently owns (loop lifetime).
fn mt_core_bind(core_bits<u64>) {
    ctx_hub_ensure()
    h<CtxTlsHub> = CTX_HUB
    tid<u64> = std.gettid()
    h.lock.lock()
    idx<i32> = ctx_tid_find(h, tid)
    if idx >= 0 {
        h.cores[idx] = core_bits
    }
    h.lock.unlock()
}

fn mt_core_unbind() {
    ctx_hub_ensure()
    h<CtxTlsHub> = CTX_HUB
    tid<u64> = std.gettid()
    h.lock.lock()
    idx<i32> = ctx_tid_find(h, tid)
    if idx >= 0 {
        h.cores[idx] = 0
    }
    h.lock.unlock()
}

// Lock-free: WorkerCore* bits for this tid, or 0.
fn mt_core_current_bits() u64 {
    h<CtxTlsHub> = CTX_HUB
    if h == null {
        return 0
    }
    tid<u64> = std.gettid()
    i<i32> = 0
    while i < CTX_TID_CAP {
        if h.tids[i] == tid {
            return h.cores[i]
        }
        i += 1
    }
    return 0
}
