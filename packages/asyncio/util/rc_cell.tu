// Single-threaded Rc; current_thread scheduler only. No atomics.

use os

// Refcount + value pair. value lifetime is the caller's responsibility.
class RcCell {
    strong   // i32 refcount, starts at 1
    value    // any pointer / dynamic value
}

// Construct with strong=1 and store value.
RcCell::init(v){
    this.strong = 1
    this.value = v
}

// strong+=1, returns this so callers share the same cell.
RcCell::clone(){
    this.strong += 1
    return this
}

// strong-=1; clears value when count hits zero. Underflow panics.
RcCell::drop(){
    this.strong -= 1
    if this.strong < 0 os.die("RcCell::drop underflow")
    if this.strong == 0 {
        this.value = null
    }
}

// Read value; panics on a dropped cell.
RcCell::get(){
    if this.strong <= 0 os.die("RcCell::get on dropped cell")
    return this.value
}

// Current refcount; intended for asserts/tests.
RcCell::strong_count() i32 {
    return this.strong
}
