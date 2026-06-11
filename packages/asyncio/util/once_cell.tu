// Single-threaded one-time-init container; runtime build path only.
// Distinct from sync.OnceCell which uses a cross-thread Notify protocol.

use os

// One-shot value with an init flag.
class OnceCell {
    inited   // i32 0/1
    value
}

// Reset to the uninitialised state.
OnceCell::init(){
    this.inited = 0
    this.value = null
}

// Return value when initialised; otherwise call closure() once, store, mark inited.
OnceCell::get_or_init(closure){
    if this.inited == 1 return this.value
    v = closure()
    this.value = v
    this.inited = 1
    return v
}

// Read value; panics when not yet initialised.
OnceCell::get(){
    if this.inited == 0 os.die("OnceCell::get on uninitialized cell")
    return this.value
}

OnceCell::is_initialized() bool {
    if this.inited == 1 return true
    return false
}
