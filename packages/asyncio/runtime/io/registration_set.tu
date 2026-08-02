// Owns every ScheduledIo allocated by the IO driver. Linked via typed
// ScheduledIo.prev_sio / next_sio fields so the chain is a GC-traced strong
// reference (interior raw-pointer links would be invisible to the GC and
// freed live nodes).
// RegistrationSet itself is lock-free (pending_release_count); Synced is
// guarded by Handle.synced.

use runtime
use netio
use asyncio.util

// Wake the driver after this many deferred drops so release() runs soon.
NOTIFY_AFTER<u32> = 64

// The design Synced: list of live registrations + pending drops + shutdown flag.
// Guarded exclusively by IoHandle.synced_lock (not stored here).
// pending_head uses ScheduledIo.release_next — unbounded, GC-traced, never
// freed from the close path (only IoDriver::turn releases after poll).
mem RegistrationSetSynced {
    i32          is_shutdown
    ScheduledIo* head
    ScheduledIo* tail
    u32          live_count
    ScheduledIo* pending_head
    u32          pending_count
}

// The design RegistrationSet: only the pending-release counter.
mem RegistrationSet {
    u64 pending_release_count
}

// Last pair from RegistrationSet::new — multi-ret mem pointers are lossy.
LAST_REG_SET<RegistrationSet> = null
LAST_REG_SYNCED<RegistrationSetSynced> = null

fn registration_set_last() RegistrationSet {
    return LAST_REG_SET
}
fn registration_synced_last() RegistrationSetSynced {
    return LAST_REG_SYNCED
}

// Build empty (RegistrationSet, Synced). Published via *_last helpers.
const RegistrationSet::new() i32 {
    LAST_REG_SET = null
    LAST_REG_SYNCED = null
    s<RegistrationSetSynced> = new RegistrationSetSynced
    s.is_shutdown = 0
    s.head = null
    s.tail = null
    s.live_count = 0
    s.pending_head = null
    s.pending_count = 0
    rs<RegistrationSet> = new RegistrationSet
    rs.pending_release_count = 0
    LAST_REG_SET = rs
    LAST_REG_SYNCED = s
    return 0
}

// True when the driver has shut down.
RegistrationSet::is_shutdown(synced<RegistrationSetSynced>) i32 {
    return synced.is_shutdown
}

// True when pending drops need a release pass.
RegistrationSet::needs_release() i32 {
    if this.pending_release_count != 0 {
        return 1
    }
    return 0
}

// Allocate a ScheduledIo and push_front onto synced. Caller must hold
// IoHandle.synced_lock.
RegistrationSet::allocate(synced<RegistrationSetSynced>) (i32, ScheduledIo) {
    if synced.is_shutdown != 0 {
        return 1, null
    }
    sio<ScheduledIo> = ScheduledIo::new()
    // push_front on the owning typed chain
    if synced.head != null {
        old<ScheduledIo> = synced.head
        sio.next_sio = old
        old.prev_sio = sio
    } else {
        synced.tail = sio
    }
    synced.head = sio
    synced.live_count += 1
    return 0, sio
}

// Unlink sio from the live list. Caller must hold synced_lock and guarantee
// sio is on this set.
RegistrationSet::remove(synced<RegistrationSetSynced>, sio<ScheduledIo>){
    prv<ScheduledIo> = sio.prev_sio
    nxt<ScheduledIo> = sio.next_sio
    if prv != null {
        prv.next_sio = nxt
    } else {
        synced.head = nxt
    }
    if nxt != null {
        nxt.prev_sio = prv
    } else {
        synced.tail = prv
    }
    sio.prev_sio = null
    sio.next_sio = null
    if synced.live_count > 0 {
        synced.live_count -= 1
    }
}

// Queue for later drop; returns 1 if the driver should unpark to purge.
// Caller holds synced_lock. sio stays on the live list until release() in
// IoDriver::turn (after poll) — never unlink from the close/deregister path.
RegistrationSet::deregister(synced<RegistrationSetSynced>, sio<ScheduledIo>) i32 {
    if sio.release_queued != 0 {
        return 0
    }
    sio.release_queued = 1
    sio.release_next = synced.pending_head
    synced.pending_head = sio
    synced.pending_count += 1
    pc<u32> = synced.pending_count
    this.pending_release_count = pc.(u64)
    if pc == NOTIFY_AFTER {
        return 1
    }
    if pc > NOTIFY_AFTER && (pc % NOTIFY_AFTER) == 0 {
        return 1
    }
    return 0
}

// Drain pending_release via remove. Only safe from IoDriver::turn after poll.
RegistrationSet::release(synced<RegistrationSetSynced>){
    cur<ScheduledIo> = synced.pending_head
    synced.pending_head = null
    synced.pending_count = 0
    this.pending_release_count = 0
    while cur != null {
        nxt<ScheduledIo> = cur.release_next
        cur.release_next = null
        cur.release_queued = 0
        this.remove(synced, cur)
        cur = nxt
    }
}

// Mark shutdown and detach every live ScheduledIo. Caller holds synced_lock;
// must call ScheduledIo::shutdown on each returned node *without* the lock.
// Returns the old head; nodes remain linked via next_sio for the caller walk.
RegistrationSet::shutdown(synced<RegistrationSetSynced>) ScheduledIo {
    if synced.is_shutdown != 0 {
        return null
    }
    synced.is_shutdown = 1
    synced.pending_head = null
    synced.pending_count = 0
    this.pending_release_count = 0
    head_sio<ScheduledIo> = synced.head
    synced.head = null
    synced.tail = null
    synced.live_count = 0
    return head_sio
}

// Live count snapshot. Caller must hold synced_lock.
RegistrationSet::live_count(synced<RegistrationSetSynced>) u32 {
    return synced.live_count
}
