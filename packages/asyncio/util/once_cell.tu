// Single-threaded one-time-init container; runtime build path only.
// Distinct from sync.OnceCell which uses a cross-thread Notify protocol.
// value is held as raw u64 bits (pointer / i64 payload); caller re-casts.

use os

// Initialiser callback: produces the cell's u64 value (often a pointer cast).
fn once_init_fn() u64

// One-shot value with an init flag.
mem OnceCell {
    i32 inited   // 0 = empty, 1 = initialised
    u64 value    // raw bits: pointer or i64 payload
}

// Build an empty cell.
const OnceCell::new() OnceCell {
    c<OnceCell> = new OnceCell
    c.inited = 0
    c.value  = 0
    return c
}

// Return value when initialised; otherwise call initfn() once, store, mark inited.
OnceCell::get_or_init(initfn<fc<once_init_fn>>) u64 {
    if this.inited == 1 return this.value
    v<u64> = initfn()
    this.value = v
    this.inited = 1
    return v
}

// Read value; panics when not yet initialised.
OnceCell::get() u64 {
    if this.inited == 0 os.die("OnceCell::get on uninitialized cell")
    return this.value
}

OnceCell::is_initialized() bool {
    if this.inited == 1 return true
    return false
}

