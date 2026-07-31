// Hashed timer wheel: NUM_LEVELS x LEVEL_SLOTS slots covering up to
// MAX_DURATION ms relative to `elapsed`. insert places entries on the
// shallowest level whose range covers the deadline; poll cascades level
// by level, demoting entries until they reach level 0.

use std
use runtime

NUM_LEVELS<i32>    = 6
LEVEL_MULT<u64>    = 64
MAX_DURATION<u64>  = 0xfffffffff   // (1 << 36) - 1

// Outcome of Wheel::insert.
INSERT_OK<i32>       = 0
INSERT_ELAPSED<i32>  = 1   // deadline already past elapsed
INSERT_TOO_FAR<i32>  = 2   // deadline > MAX_DURATION ahead

// Outcome of Wheel::poll_at / next_expiration.
EXPIR_NONE<i32>  = 0
EXPIR_FOUND<i32> = 1

// Resolution of one slot at the given level (in ms).
fn slot_range(level<i32>) u64 {
    if level == 0 return 1
    r<u64> = 1
    for i<i32> = 0 ; i < level ; i += 1 {
        r = r * LEVEL_MULT
    }
    return r
}

// Total span of a level (slot_range * 64).
fn level_range(level<i32>) u64 {
    return slot_range(level) * LEVEL_MULT
}

// Pick the shallowest level that fits when_relative. when_relative==0 -> 0.
fn level_for(when_relative<u64>) i32 {
    if when_relative == 0 return 0
    span<u64> = LEVEL_MULT
    for lv<i32> = 0 ; lv < NUM_LEVELS ; lv += 1 {
        if when_relative < span return lv
        span = span * LEVEL_MULT
    }
    return NUM_LEVELS - 1
}

// Slot within `level` for `deadline_ms` (taking elapsed into account).
fn slot_for(level<i32>, elapsed<u64>, deadline_ms<u64>) i32 {
    sr<u64> = slot_range(level)
    idx<u64> = (deadline_ms / sr) & LEVEL_MASK
    return idx.(i32)
}

// Hashed timer wheel.
mem Wheel {
    u64         elapsed       // monotonic ms already poll()ed past
    u64*        levels        // raw bits of Level*; length NUM_LEVELS
    EntryList*  pending       // entries already fired but not yet drained
}

// Build an empty wheel anchored at elapsed=0.
const Wheel::new() Wheel {
    w<Wheel> = new Wheel
    w.elapsed = 0
    arr<u64*> = runtime.malloc(sizeof(u64) * NUM_LEVELS.(u64), 0.(i8), 1.(i8))
    for i<i32> = 0 ; i < NUM_LEVELS ; i += 1 {
        lv<Level> = Level::new(i.(u32))
        arr[i] = lv.(u64)
    }
    w.levels  = arr
    w.pending = EntryList::new()
    return w
}

// Resolve Level* bits stored in Wheel.levels[lv].
fn level_at(levels<u64*>, lv<i32>) Level {
    bits<u64> = levels[lv]
    return bits.(Level)
}

// Insert entry. Returns (INSERT_OK, deadline_ms) on success. INSERT_ELAPSED
// when the deadline is at or before elapsed (caller should fire it now);
// INSERT_TOO_FAR when the deadline is beyond MAX_DURATION.
Wheel::insert(item<TimerShared>, deadline_ms<u64>) (i32, u64) {
    if deadline_ms <= this.elapsed return INSERT_ELAPSED, this.elapsed
    rel<u64> = deadline_ms - this.elapsed
    if rel > MAX_DURATION return INSERT_TOO_FAR, this.elapsed + MAX_DURATION

    lv<i32> = level_for(rel)
    sl<i32> = slot_for(lv, this.elapsed, deadline_ms)
    item.cached_when = deadline_ms

    layer<Level> = level_at(this.levels, lv)
    layer.add_entry(sl, item)
    return INSERT_OK, deadline_ms
}

// Detach item from its current slot. Caller must have inserted it via
// Wheel::insert; cached_when tells us which level/slot to look in.
Wheel::remove(item<TimerShared>) i32 {
    cw<u64> = item.cached_when
    if cw == STATE_DEREGISTERED return 0
    if cw <= this.elapsed return 0
    rel<u64> = cw - this.elapsed
    lv<i32> = level_for(rel)
    sl<i32> = slot_for(lv, this.elapsed, cw)
    layer<Level> = level_at(this.levels, lv)
    layer.remove_entry(sl, item)
    item.cached_when = STATE_DEREGISTERED
    return 0
}

// Earliest deadline remaining in the wheel. Returns (EXPIR_FOUND, ms) or
// (EXPIR_NONE, 0).
// Must start from the slot corresponding to `elapsed` (not slot 0): a later
// timer can occupy a lower slot index and would otherwise look "next",
// causing park to oversleep and fire multiple timers together.
Wheel::poll_at() (i32, u64) {
    best_found<i32> = EXPIR_NONE
    best_dl<u64> = 0
    for lv<i32> = 0 ; lv < NUM_LEVELS ; lv += 1 {
        layer<Level> = level_at(this.levels, lv)
        if layer.occupied == 0 {
            continue
        }
        sr<u64> = slot_range(lv)
        lr<u64> = level_range(lv)
        cur_idx<u64> = (this.elapsed / sr) & LEVEL_MASK
        cur_slot<i32> = cur_idx.(i32)
        sl<i32> = layer.next_occupied_slot(cur_slot)
        if sl < 0 {
            sl = layer.next_occupied_slot(0)
        }
        if sl < 0 {
            continue
        }
        mask<u64> = lr - 1
        not_mask<u64> = 0xffffffffffffffff - mask
        level_start<u64> = this.elapsed & not_mask
        base<u64> = level_start + sl.(u64) * sr
        if base <= this.elapsed {
            base = base + lr
        }
        if best_found == EXPIR_NONE || base < best_dl {
            best_found = EXPIR_FOUND
            best_dl = base
        }
    }
    return best_found, best_dl
}

// Cascade entries on lv0 slot (already extracted) down: simply move them
// to pending. Higher levels demote to a lower level via re-insert below.
Wheel::cascade_pending(list<EntryList>){
    loop {
        e<TimerShared> = list.pop_front()
        if e == null {
            break
        }
        this.pending.push_back(e)
    }
}

// Demote a higher-level slot list down by re-inserting each entry; entries
// whose deadline is now past elapsed move straight to pending.
Wheel::cascade_level(list<EntryList>){
    loop {
        e<TimerShared> = list.pop_front()
        if e == null {
            break
        }
        if e.cached_when <= this.elapsed {
            this.pending.push_back(e)
            continue
        }
        rel<u64> = e.cached_when - this.elapsed
        lv<i32> = level_for(rel)
        sl<i32> = slot_for(lv, this.elapsed, e.cached_when)
        layer<Level> = level_at(this.levels, lv)
        layer.add_entry(sl, e)
    }
}

// Advance the wheel to `now`. The design compares slot *deadlines* to `now`,
// not raw slot indices — `sl <= target_slot` skips entries when now jumps
// past the slot index without wrapping (elapsed=0, when=50, now=100).
Wheel::poll(now<u64>) u64 {
    if now <= this.elapsed return this.elapsed
    target<u64> = now

    loop {
        if this.elapsed >= target break

        moved<i32> = 0
        for lv<i32> = 0 ; lv < NUM_LEVELS ; lv += 1 {
            layer<Level> = level_at(this.levels, lv)
            sr<u64> = slot_range(lv)
            lr<u64> = level_range(lv)
            cur_idx<u64> = (this.elapsed / sr) & LEVEL_MASK
            cur_slot<i32> = cur_idx.(i32)
            sl<i32> = layer.next_occupied_slot(cur_slot)
            if sl < 0 {
                // Wrapped: occupied bits only below cur_slot.
                sl = layer.next_occupied_slot(0)
            }
            if sl < 0 {
                continue
            }
            mask<u64> = lr - 1
            not_mask<u64> = 0xffffffffffffffff - mask
            level_start<u64> = this.elapsed & not_mask
            deadline<u64> = level_start + sl.(u64) * sr
            if deadline <= this.elapsed {
                deadline = deadline + lr
            }
            if deadline > target {
                continue
            }
            list<EntryList> = layer.take_slot(sl)
            if lv == 0 {
                this.cascade_pending(list)
            } else {
                this.cascade_level(list)
            }
            this.elapsed = deadline
            if this.elapsed > target {
                this.elapsed = target
            }
            moved = 1
            break
        }
        if moved == 0 {
            this.elapsed = target
            break
        }
    }

    return this.elapsed
}

// Drain every fired entry as a list. Caller is responsible for actually
// invoking the wakers; the wheel keeps no further references afterwards.
Wheel::take_pending() EntryList {
    out<EntryList> = EntryList::new()
    out.front_bits = this.pending.front_bits
    out.back_bits = this.pending.back_bits
    this.pending.front_bits = 0
    this.pending.back_bits = 0
    return out
}

