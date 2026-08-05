// Per-OS-thread active poll waker bits, keyed by gettid().
// Mother Context is thread-local. core_cid() can be -1 around soft-syscall /
// core detach windows; a zero waker then Pending with no IO registration
// left READABLE orphans (joint hang dump). Tid is stable for the OS thread.
//
// Hub must be published from poll_ctx_hub_init (builder, single-threaded)
// before workers run. Lock only on first claim of a tid slot. Publish/load of
// ctxs[idx] is single-writer (this OS thread).

use runtime
use std

POLL_TID_CAP<i32> = 256

mem PollTidHub {
    runtime.MutexInter* lock
    u64* tids
    u64* ctxs
}

POLL_TID_HUB<PollTidHub> = null

fn poll_ctx_hub_create() PollTidHub {
    h<PollTidHub> = new PollTidHub
    lk<runtime.MutexInter> = new runtime.MutexInter
    lk.init()
    h.lock = lk
    n<u64> = POLL_TID_CAP.(u64)
    h.tids = runtime.malloc(8 * n, 1.(i8), 1.(i8))
    h.ctxs = runtime.malloc(8 * n, 0.(i8), 1.(i8))
    i<i32> = 0
    while i < POLL_TID_CAP {
        h.tids[i] = 0
        h.ctxs[i] = 0
        i += 1
    }
    return h
}

// Builder calls this before spawning workers — single-threaded publish.
fn poll_ctx_hub_init() {
    if POLL_TID_HUB != null {
        return
    }
    POLL_TID_HUB = poll_ctx_hub_create()
}

fn poll_ctx_hub_ensure() {
    if POLL_TID_HUB != null {
        return
    }
    // Fallback if a path skipped init; still racy under MT — prefer init().
    POLL_TID_HUB = poll_ctx_hub_create()
}

fn poll_tid_find(h<PollTidHub>, tid<u64>) i32 {
    i<i32> = 0
    while i < POLL_TID_CAP {
        if h.tids[i] == tid {
            return i
        }
        i += 1
    }
    return -1
}

fn poll_tid_claim_locked(h<PollTidHub>, tid<u64>) i32 {
    found<i32> = poll_tid_find(h, tid)
    if found >= 0 {
        return found
    }
    j<i32> = 0
    while j < POLL_TID_CAP {
        if h.tids[j] == 0 {
            h.tids[j] = tid
            h.ctxs[j] = 0
            return j
        }
        j += 1
    }
    h.tids[POLL_TID_CAP - 1] = tid
    h.ctxs[POLL_TID_CAP - 1] = 0
    return POLL_TID_CAP - 1
}

fn poll_ctx_set(ctx<u64>) u64 {
    poll_ctx_hub_ensure()
    h<PollTidHub> = POLL_TID_HUB
    tid<u64> = std.gettid()
    idx<i32> = poll_tid_find(h, tid)
    if idx < 0 {
        h.lock.lock()
        idx = poll_tid_claim_locked(h, tid)
        h.lock.unlock()
    }
    prev<u64> = h.ctxs[idx]
    h.ctxs[idx] = ctx
    return prev
}

fn poll_ctx_get() u64 {
    h<PollTidHub> = POLL_TID_HUB
    if h == null {
        return 0
    }
    tid<u64> = std.gettid()
    idx<i32> = poll_tid_find(h, tid)
    if idx < 0 {
        return 0
    }
    return h.ctxs[idx]
}
