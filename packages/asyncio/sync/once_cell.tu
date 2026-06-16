// Cross-thread one-shot init container. State is monotonic:
//   UNINIT -> INIT_RUN -> INIT_DONE
// Only the thread that wins the UNINIT->INIT_RUN CAS runs the initializer;
// the rest park on `ready` and wake on INIT_DONE.

use std.atomic
use asyncio.error as aerr

UNINIT<i32>     = 0
INIT_RUN<i32>   = 1
INIT_DONE<i32>  = 2

// Caller-supplied initializer; produces the cell's u64 value.
fn once_init_factory() u64

// Cross-thread one-shot init container.
mem OnceCell {
    i32     state    // atomic; UNINIT / INIT_RUN / INIT_DONE
    u64     value    // raw bits; pointer or i64 payload
    Notify* ready
}

// Build an empty cell.
const OnceCell::new() OnceCell* {
    c<OnceCell> = new OnceCell
    c.state = UNINIT
    c.value = 0
    c.ready = Notify::new()
    return &c
}

// Returns true once initialised.
OnceCell::is_initialized() bool {
    if atomic.load(&this.state) == INIT_DONE return true
    return false
}

// Set the value if the cell is still UNINIT. Returns 0 on success,
// asyncio.error.AlreadyConsumed if a value is already present.
OnceCell::set(v<u64>) i32 {
    if atomic.cas(&this.state, UNINIT, INIT_DONE) == 0 {
        return aerr.AlreadyConsumed
    }
    this.value = v
    this.ready.notify_waiters()
    return 0
}

// Read the value; (0, v) on success, (Cancelled, 0) when uninitialised.
OnceCell::get() (i32, u64) {
    if atomic.load(&this.state) != INIT_DONE {
        return aerr.Cancelled, 0
    }
    return 0, this.value
}

// Initialise on first call, return the stored value on every call. The
// initializer runs at most once; concurrent waiters park on `ready`.
async OnceCell::get_or_init(initfn<fc<once_init_factory>>){
    loop {
        cur<i32> = atomic.load(&this.state)
        if cur == INIT_DONE {
            return 0, this.value
        }
        if cur == UNINIT {
            // Try to claim the slot.
            if atomic.cas(&this.state, UNINIT, INIT_RUN) != 0 {
                v<u64> = initfn()
                this.value = v
                atomic.store(&this.state, INIT_RUN, INIT_DONE)
                this.ready.notify_waiters()
                return 0, v
            }
            // Lost the race; fall through and wait.
        }
        // INIT_RUN — wait for the running initializer to finish.
        code<i32> = this.ready.notified().await
        if code != 0 return code, 0
    }
    return 0, 0
}

