// Cross-thread one-shot init container. State is monotonic:
//   UNINIT -> INIT_RUN -> INIT_DONE
// Only the thread that wins the UNINIT->INIT_RUN CAS runs the initializer;
// the rest park on ready_notify and wake on INIT_DONE.

use std.atomic

UNINIT<i32>     = 0
INIT_RUN<i32>   = 1
INIT_DONE<i32>  = 2

OnceErrAlreadyConsumed<i32> = 0x03020007
OnceErrCancelled<i32>       = 0x03020001

// Cross-thread one-shot init container.
mem OnceCell {
    i32     cell_state    // atomic; UNINIT / INIT_RUN / INIT_DONE
    u64     slot_bits     // tokio: value payload as raw bits
    Notify* ready_notify
}

// Build an empty cell.
const OnceCell::new() OnceCell {
    c<OnceCell> = new OnceCell
    c.cell_state    = UNINIT
    c.slot_bits     = 0
    c.ready_notify  = Notify::new()
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
    this.slot_bits = v
    this.ready_notify.notify_waiters()
    return 0
}

// Read the value; (0, v) on success, (Cancelled, 0) when uninitialised.
OnceCell::get() (i32, u64) {
    if atomic.load(&this.cell_state) != INIT_DONE {
        return OnceErrCancelled, 0
    }
    return 0, this.slot_bits
}

// Async leaf for get_or_init wait loop.
mem OnceInitFut: async {
    OnceCell* hub
    u64       ready_bits
    i32       stage
    Notified* pending_nf
}

OnceInitFut::init(hub<OnceCell>){
    this.hub = hub
    this.ready_bits = 0
    this.stage = 0
    this.pending_nf = null
}

OnceInitFut::poll(ctx){
    hub<OnceCell> = this.hub
    cur<i32> = atomic.load(&hub.cell_state)
    if cur == INIT_DONE {
        this.ready_bits = hub.slot_bits
        this.stage = 2
        return runtime.PollReady, 0
    }
    if cur == UNINIT {
        if atomic.cas(&hub.cell_state, UNINIT, INIT_RUN) != 0 {
            this.stage = 2
            return runtime.PollReady, 1
        }
    }
    if this.pending_nf == null {
        this.pending_nf = notified_from_notify(hub.ready_notify)
    }
    nfy<Notified> = this.pending_nf
    pcode<i32> = nfy.poll(ctx)
    if pcode == runtime.PollReady {
        this.pending_nf = null
    }
    return runtime.PollPending
}

// Initialise on first call, return the stored value on every call.
async OnceCell::get_or_init(initfn){
    loop {
        cur<i32> = atomic.load(&this.cell_state)
        if cur == INIT_DONE {
            return 0, this.slot_bits
        }
        fut<OnceInitFut> = new OnceInitFut
        fut.init(this)
        code<i32> = fut.await
        if code == 1 {
            v<u64> = initfn()
            this.slot_bits = v
            atomic.store(&this.cell_state, INIT_DONE)
            this.ready_notify.notify_waiters()
            return 0, v
        }
        if code != 0 return code, 0
    }
    return 0, 0
}
