// Cross-thread one-shot init container. State is monotonic:
//   UNINIT -> INIT_RUN -> INIT_DONE
// Only the thread that wins the UNINIT->INIT_RUN CAS runs the initializer;
// the rest park on `ready` and wake on INIT_DONE.

use std.atomic
use asyncio.sync as asyncsync

UNINIT<i32>     = 0
INIT_RUN<i32>   = 1
INIT_DONE<i32>  = 2

OnceErrAlreadyConsumed<i32> = 0x03020007
OnceErrCancelled<i32>       = 0x03020001

// Cross-thread one-shot init container.
mem OnceCell {
    i32     cell_state    // atomic; UNINIT / INIT_RUN / INIT_DONE
    u64     value         // raw bits; pointer or i64 payload
    asyncsync.Notify* ready_notify
}

// Build an empty cell.
const OnceCell::new() OnceCell {
    c<OnceCell> = new OnceCell
    c.cell_state    = UNINIT
    c.value         = 0
    c.ready_notify  = asyncsync.Notify::new()
    return c
}

// Returns 1 once initialised.
OnceCell::is_initialized() i32 {
    if atomic.load(&this.cell_state) == INIT_DONE return 1
    return 0
}

// Set the value if the cell is still UNINIT. Returns 0 on success,
// AlreadyConsumed if a value is already present.
OnceCell::set(v<u64>) i32 {
    if atomic.cas(&this.cell_state, UNINIT, INIT_DONE) == 0 {
        return OnceErrAlreadyConsumed
    }
    this.value = v
    this.ready_notify.notify_waiters()
    return 0
}

// Read the value; (0, v) on success, (Cancelled, 0) when uninitialised.
OnceCell::get() (i32, u64) {
    if atomic.load(&this.cell_state) != INIT_DONE {
        return OnceErrCancelled, 0
    }
    return 0, this.value
}

// Initialise on first call, return the stored value on every call.
async OnceCell::get_or_init(initfn){
    loop {
        cur<i32> = atomic.load(&this.cell_state)
        if cur == INIT_DONE {
            return 0, this.value
        }
        if cur == UNINIT {
            if atomic.cas(&this.cell_state, UNINIT, INIT_RUN) != 0 {
                v<u64> = initfn()
                this.value = v
                atomic.store(&this.cell_state, INIT_DONE)
                this.ready_notify.notify_waiters()
                return 0, v
            }
        }
        code<i32> = this.ready_notify.notified().await
        if code != 0 return code, 0
    }
    return 0, 0
}
