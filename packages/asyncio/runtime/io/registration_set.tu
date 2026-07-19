// Owns every ScheduledIo allocated by the IO driver. Linked via
// ScheduledIo.linked_list_pointers so shutdown can drain them all.
// Mother: tokio::runtime::io::registration_set — RegistrationSet itself is
// lock-free (pending_release_count); Synced is guarded by Handle.synced.

use runtime
use netio
use asyncio.util

NOTIFY_AFTER<u32> = 16
PENDING_CAP<u32>  = 32

// Mother Synced: list of live registrations + pending drops + shutdown flag.
// Guarded exclusively by IoHandle.synced_lock (not stored here).
mem RegistrationSetSynced {
    i32          is_shutdown
    ScheduledIo* head
    ScheduledIo* tail
    u32          live_count
    u64          pending_slots[32] // ScheduledIo* bits awaiting release
    u32          pending_count
}

// Mother RegistrationSet: only the pending-release counter.
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
    s.pending_count = 0
    rs<RegistrationSet> = new RegistrationSet
    rs.pending_release_count = 0
    LAST_REG_SET = rs
    LAST_REG_SYNCED = s
    return 0
}

// True when the driver has shut down (mother: is_shutdown).
RegistrationSet::is_shutdown(synced<RegistrationSetSynced>) i32 {
    return synced.is_shutdown
}

// True when pending drops need a release pass (mother: needs_release).
RegistrationSet::needs_release() i32 {
    if this.pending_release_count != 0 {
        return 1
    }
    return 0
}

// Allocate a ScheduledIo and push_front onto synced. Caller must hold
// IoHandle.synced_lock (mother: allocate(&mut synced.lock())).
RegistrationSet::allocate(synced<RegistrationSetSynced>) (i32, ScheduledIo) {
    if synced.is_shutdown != 0 {
        return 1, null
    }
    sio<ScheduledIo> = ScheduledIo::new()
    // push_front
    if synced.head != null {
        old<ScheduledIo> = synced.head
        sio.linked_list_pointers.next = &old.linked_list_pointers
        old.linked_list_pointers.prev = &sio.linked_list_pointers
    } else {
        synced.tail = sio
    }
    synced.head = sio
    synced.live_count += 1
    return 0, sio
}

// Unlink sio from the live list. Caller must hold synced_lock and guarantee
// sio is on this set (mother: unsafe remove).
RegistrationSet::remove(synced<RegistrationSetSynced>, sio<ScheduledIo>){
    p<util.Pointers> = sio.linked_list_pointers
    if p.prev != null {
        prev_node<util.Pointers> = p.prev
        prev_node.next = p.next
    } else {
        if p.next == null {
            synced.head = null
        } else {
            nxt<util.Pointers> = p.next
            synced.head = nxt.(ScheduledIo)
        }
    }
    if p.next != null {
        next_node<util.Pointers> = p.next
        next_node.prev = p.prev
    } else {
        if p.prev == null {
            synced.tail = null
        } else {
            prv<util.Pointers> = p.prev
            synced.tail = prv.(ScheduledIo)
        }
    }
    sio.linked_list_pointers.prev = null
    sio.linked_list_pointers.next = null
    if synced.live_count > 0 {
        synced.live_count -= 1
    }
}

// Queue for later drop; returns 1 if the driver should unpark to purge
// (mother: deregister → notify when count == NOTIFY_AFTER).
RegistrationSet::deregister(synced<RegistrationSetSynced>, sio<ScheduledIo>) i32 {
    if synced.pending_count >= PENDING_CAP {
        // Cap full: remove immediately so we never leak.
        this.remove(synced, sio)
        return 0
    }
    synced.pending_slots[synced.pending_count] = sio.(u64)
    synced.pending_count += 1
    pc<u32> = synced.pending_count
    this.pending_release_count = pc.(u64)
    if pc == NOTIFY_AFTER {
        return 1
    }
    return 0
}

// Drain pending_release via remove (mother: release).
RegistrationSet::release(synced<RegistrationSetSynced>){
    i<u32> = 0
    while i < synced.pending_count {
        bits<u64> = synced.pending_slots[i]
        if bits != 0 {
            sio<ScheduledIo> = bits.(ScheduledIo)
            this.remove(synced, sio)
        }
        synced.pending_slots[i] = 0
        i += 1
    }
    synced.pending_count = 0
    this.pending_release_count = 0
}

// Mark shutdown and detach every live ScheduledIo. Caller holds synced_lock;
// must call ScheduledIo::shutdown on each returned node *without* the lock
// (mother: Driver::shutdown).
// Returns the old head; nodes remain linked via linked_list_pointers.next.
RegistrationSet::shutdown(synced<RegistrationSetSynced>) ScheduledIo {
    if synced.is_shutdown != 0 {
        return null
    }
    synced.is_shutdown = 1
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
