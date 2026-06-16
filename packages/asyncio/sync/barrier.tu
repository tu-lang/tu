// Synchronisation barrier: every wait() blocks until `n` participants
// arrive. The last arrival wakes the rest by bumping `generation` and
// firing notify_waiters. The wait future re-checks generation on each
// poll so a concurrent notify cannot wake stragglers from the next round.

use runtime

// Barrier capacity + generation counter + Notify hand-off.
mem Barrier {
    runtime.MutexInter lock
    i32                n             // total participants per round
    i32                arrived        // current round arrival count
    i32                generation     // monotonic round counter
    Notify*            notify
}

// Build a Barrier expecting n participants per round.
const Barrier::new(n<i32>) Barrier* {
    b<Barrier> = new Barrier
    b.lock.init()
    b.n          = n
    b.arrived    = 0
    b.generation = 0
    b.notify     = Notify::new()
    return &b
}

// Wait for the round to complete. Returns (0, is_leader) where is_leader
// is 1 for the participant that triggered the wake (matches tokio's
// BarrierWaitResult::is_leader).
async Barrier::wait(){
    this.lock.lock()
    arrival_gen<i32> = this.generation
    this.arrived += 1
    if this.arrived == this.n {
        this.arrived    = 0
        this.generation = this.generation + 1
        this.lock.unlock()
        this.notify.notify_waiters()
        return 0, 1
    }
    this.lock.unlock()

    // Wait until generation moves past arrival_gen.
    loop {
        code<i32> = this.notify.notified().await
        if code != 0 return code, 0
        this.lock.lock()
        cur_gen<i32> = this.generation
        this.lock.unlock()
        if cur_gen != arrival_gen break
    }
    return 0, 0
}

