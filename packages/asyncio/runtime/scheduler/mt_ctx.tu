// Per-OS-thread active RuntimeContext + poll-scoped lifo_slot address.
// Mother with_current: while a worker polls, spawn may push LIFO.
// Wake/Schedule stays inject — deferring wakes SEGV'd (optimize 2026-07-29h).
// TLS holds &WorkerCore.lifo_slot (interior ptr), NOT RawTask* values —
// RawTask* in unscanned TLS is GC-unsafe (SEGV under concurrent GC).
// Never cast WorkerCore from TLS (SEGV; optimize 2026-07-29e).

use runtime
use std
use std.atomic

CTX_TID_CAP<i32> = 64

mem CtxTlsHub {
    runtime.MutexInter* lock
    u64* tids
    u64* ctxs
    u64* cores              // WorkerCore* bits while worker holds the core
    u64* poll_lifo_ptrs     // &WorkerCore.lifo_slot as u64* bits during poll
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
    h.tids = runtime.malloc(8 * n, 0.(i8), 1.(i8))
    h.ctxs = runtime.malloc(8 * n, 0.(i8), 1.(i8))
    h.cores = runtime.malloc(8 * n, 0.(i8), 1.(i8))
    h.poll_lifo_ptrs = runtime.malloc(8 * n, 0.(i8), 1.(i8))
    i<i32> = 0
    while i < CTX_TID_CAP {
        h.tids[i] = 0
        h.ctxs[i] = 0
        h.cores[i] = 0
        h.poll_lifo_ptrs[i] = 0
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
            h.poll_lifo_ptrs[j] = 0
            return j
        }
        j += 1
    }
    h.tids[0] = tid
    h.cores[0] = 0
    h.poll_lifo_ptrs[0] = 0
    return 0
}

fn ctx_tid_slot_lockfree(tid<u64>) i32 {
    h<CtxTlsHub> = CTX_HUB
    if h == null {
        return -1
    }
    i<i32> = 0
    while i < CTX_TID_CAP {
        if h.tids[i] == tid {
            return i
        }
        i += 1
    }
    return -1
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
        h.poll_lifo_ptrs[idx] = 0
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
        h.poll_lifo_ptrs[idx] = 0
    }
    h.lock.unlock()
}

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

// ---- poll-scoped lifo_slot address (mother with_current while polling) ----

// Publish &core.lifo_slot for spawn_local this poll only.
// ptr_bits is u64* bits from &WorkerCore.lifo_slot (typed core in run_task).
fn mt_poll_sched_enter(ptr_bits<u64>) {
    ctx_hub_ensure()
    h<CtxTlsHub> = CTX_HUB
    tid<u64> = std.gettid()
    idx<i32> = ctx_tid_slot_lockfree(tid)
    if idx < 0 {
        h.lock.lock()
        idx = ctx_tid_claim(h, tid)
        h.lock.unlock()
    }
    if idx >= 0 && idx < CTX_TID_CAP {
        h.poll_lifo_ptrs[idx] = ptr_bits
    }
}

fn mt_poll_sched_exit() {
    h<CtxTlsHub> = CTX_HUB
    if h == null {
        return
    }
    tid<u64> = std.gettid()
    idx<i32> = ctx_tid_slot_lockfree(tid)
    if idx >= 0 {
        h.poll_lifo_ptrs[idx] = 0
    }
}

// &lifo_slot bits if inside run_task, else 0.
fn mt_poll_lifo_ptr_bits() u64 {
    h<CtxTlsHub> = CTX_HUB
    if h == null {
        return 0
    }
    tid<u64> = std.gettid()
    i<i32> = 0
    while i < CTX_TID_CAP {
        if h.tids[i] == tid {
            return h.poll_lifo_ptrs[i]
        }
        i += 1
    }
    return 0
}

// Mother LIFO take+set via interior pointer. Returns prev RawTask* bits.
fn mt_poll_lifo_swap(new_bits<u64>) u64 {
    ptr_bits<u64> = mt_poll_lifo_ptr_bits()
    if ptr_bits == 0 {
        return 0
    }
    slotp<u64*> = null
    slotp = ptr_bits
    prev<u64> = atomic.load64(slotp)
    atomic.store64(slotp, new_bits)
    return prev
}
