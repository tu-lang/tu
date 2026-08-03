// Per-OS-thread active poll waker bits, keyed by runtime.core_cid().
// Mother Context is thread-local. A process-global ACTIVE_POLL_CTX races when
// multiple multi_thread workers call harness_poll concurrently — join/IO
// wakers get the wrong RawTask* and SEGV / hang under load.
//
// Each Core has a unique cid; one writer per slot, no lock / no CAS.

use runtime

POLL_CID_CAP<i32> = 1024

mem PollCidHub {
    u64* ctxs
}

POLL_CID_HUB<PollCidHub> = null

fn poll_ctx_hub_ensure() {
    if POLL_CID_HUB != null {
        return
    }
    h<PollCidHub> = new PollCidHub
    n<u64> = POLL_CID_CAP.(u64)
    // Strong roots while a worker is inside harness_poll: soft-syscall STW can
    // miss register-only task pointers; the cid slot must keep RawTask alive.
    h.ctxs = runtime.malloc(8 * n, 0.(i8), 1.(i8))
    i<i32> = 0
    while i < POLL_CID_CAP {
        h.ctxs[i] = 0
        i += 1
    }
    POLL_CID_HUB = h
}

// Builder / block_on call before any worker poll.
fn poll_ctx_hub_init() {
    poll_ctx_hub_ensure()
}

// Publish ctx for this OS thread's Core; returns previous (nesting).
fn poll_ctx_set(ctx<u64>) u64 {
    poll_ctx_hub_ensure()
    h<PollCidHub> = POLL_CID_HUB
    id<i32> = runtime.core_cid()
    if id < 0 || id >= POLL_CID_CAP {
        return 0
    }
    prev<u64> = h.ctxs[id]
    h.ctxs[id] = ctx
    return prev
}

// Current Core's published poll ctx, or 0.
fn poll_ctx_get() u64 {
    h<PollCidHub> = POLL_CID_HUB
    if h == null {
        return 0
    }
    id<i32> = runtime.core_cid()
    if id < 0 || id >= POLL_CID_CAP {
        return 0
    }
    return h.ctxs[id]
}
