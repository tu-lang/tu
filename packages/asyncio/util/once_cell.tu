// OnceCell: single-threaded one-time-init container
// Related: packages-asyncio-runtime task 2.16, R32.1
// Design: design §25.7
//
// Reserved for the runtime build path: the Builder constructs the unique
// BlockingPool / Driver / Notify singletons here.
// Distinct from sync.OnceCell:
//   - sync.OnceCell uses a multi-threaded Notify protocol;
//   - util.OnceCell assumes every access happens on the builder thread, with
//     no atomics and no waker.

use os

class OnceCell {
    inited   // i32 0=not initialised, 1=initialised
    value    // arbitrary pointer / dynamic value
}

OnceCell::init(){
    this.inited = 0
    this.value = null
}

// get_or_init(closure): return value when initialised, otherwise call
// closure() to produce a value, store it, and mark inited.
//   closure must be a no-arg callable (fn(){...} or func(){...}).
OnceCell::get_or_init(closure){
    if this.inited == 1 return this.value
    v = closure()
    this.value = v
    this.inited = 1
    return v
}

// get(): return value; panics if the cell is not initialised
OnceCell::get(){
    if this.inited == 0 os.die("OnceCell::get on uninitialized cell")
    return this.value
}

// is_initialized(): whether init has run
OnceCell::is_initialized() bool {
    if this.inited == 1 return true
    return false
}
