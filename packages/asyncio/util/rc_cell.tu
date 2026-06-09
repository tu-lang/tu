// Single-threaded reference count (Rc)
// Related: packages-asyncio-runtime task 2.7 / 2.8, R13.1, R13.6
// Design: design §25.3
//
// Reserved for the current_thread scheduler: every operation skips atomics, so
// sharing across threads would break the invariants.
// Fields: strong = current refcount (>=1 alive, 0 means data has been released);
//         value  = arbitrary pointer (dynamic value).
// new() starts with strong=1; clone() bumps, drop() decrements; once it hits 0
// callers must not read value any more.

use os

class RcCell {
    strong   // i32 reference count
    value    // void* (any pointer / dynamic value)
}

// new(v): build an RcCell with strong=1
RcCell::init(v){
    this.strong = 1
    this.value = v
}

// clone(): strong+=1 and return this so callers share the same metadata.
//   The return type is intentionally dynamic; callers may assign it to an
//   RcCell variable as they need.
RcCell::clone(){
    this.strong += 1
    return this
}

// drop(): strong-=1; clear value when it reaches zero.
//   This Rc never frees value itself (lifetime is the caller's responsibility).
//   strong < 0 is a programmer error and panics immediately.
RcCell::drop(){
    this.strong -= 1
    if this.strong < 0 os.die("RcCell::drop underflow")
    if this.strong == 0 {
        this.value = null
    }
}

// get(): return the value pointer; strong must be >= 1
RcCell::get(){
    if this.strong <= 0 os.die("RcCell::get on dropped cell")
    return this.value
}

// strong_count(): expose the current refcount, intended for assertions/tests
RcCell::strong_count() i32 {
    return this.strong
}
