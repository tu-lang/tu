// Single-threaded Rc; current_thread scheduler only. No atomics.
// value is held as raw u64 bits (pointer / i64 payload); the caller
// re-casts via obj.(Type) when reading.

use os

// Refcount + value pair. value lifetime is the caller's responsibility.
mem RcCell {
    i64 strong   // refcount, starts at 1; underflow panics
    u64 value    // raw bits: pointer or i64 payload
}

// Build a fresh cell with strong=1 and the supplied value.
const RcCell::new(v<u64>) RcCell* {
    c<RcCell> = new RcCell
    c.strong = 1
    c.value  = v
    return c
}

// strong+=1, returns this so callers share the same cell.
RcCell::clone() RcCell* {
    this.strong += 1
    return this
}

// strong-=1; clears value when count hits zero. Underflow panics.
RcCell::drop(){
    this.strong -= 1
    if this.strong < 0 os.die("RcCell::drop underflow")
    if this.strong == 0 {
        this.value = 0
    }
}

// Read value bits; panics on a dropped cell.
RcCell::get() u64 {
    if this.strong <= 0 os.die("RcCell::get on dropped cell")
    return this.value
}

// Current refcount; intended for asserts/tests.
RcCell::strong_count() i64 {
    return this.strong
}

