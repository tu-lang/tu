// Synchronisation barrier: every wait blocks until `n` participants arrive.
// The last arrival wakes the rest by bumping generation and notify_waiters.
// The wait future re-checks generation on each poll so a concurrent notify
// cannot wake stragglers from the next round.

use runtime

// Barrier capacity + generation counter + Notify hand-off.
mem Barrier {
    runtime.MutexInter* gate_lock
    i32         n             // total participants per round
    i32         arrived       // current round arrival count
    i32         generation    // monotonic round counter
    Notify*     wake_hub
}

// Build a Barrier expecting n participants per round.
const Barrier::new(n<i32>) Barrier {
    b<Barrier> = new Barrier
    b.gate_lock = new runtime.MutexInter
    b.gate_lock.init()
    b.n          = n
    b.arrived    = 0
    b.generation = 0
    b.wake_hub = Notify::new()
    return b
}

// Async leaf for one Barrier wait. Prefer barrier_wait_fut_bits across pkgs —
// member async multi-return poisons later MT block_on (same class as Mutex::lock).
mem BarrierWaitFut: async {
    Barrier*  hub
    i32       arrival_gen
    i32       leader_flag   // 1 when this waiter triggered the wake
    i32       stage
    Notified* pending_nf
}

BarrierWaitFut::init(hub<Barrier>){
    this.hub = hub
    this.pending_nf = null
    hub.gate_lock.lock()
    this.arrival_gen = hub.generation
    hub.arrived += 1
    if hub.arrived == hub.n {
        hub.arrived    = 0
        hub.generation = hub.generation + 1
        hub.gate_lock.unlock()
        hub.wake_hub.notify_waiters()
        this.leader_flag = 1
        this.stage = 2
        return
    }
    hub.gate_lock.unlock()
    this.leader_flag = 0
    this.stage = 0
}

// Ready value is leader_flag (0/1); Pending while waiting for the generation bump.
BarrierWaitFut::poll(ctx){
    if this.stage == 2 {
        return runtime.PollReady, this.leader_flag.(i64)
    }
    hub<Barrier> = this.hub
    hub.gate_lock.lock()
    cur_gen<i32> = hub.generation
    hub.gate_lock.unlock()
    if cur_gen != this.arrival_gen {
        this.stage = 2
        return runtime.PollReady, this.leader_flag.(i64)
    }
    if this.pending_nf == null {
        this.pending_nf = notified_from_notify(hub.wake_hub)
    }
    nfy<Notified> = this.pending_nf
    pcode<i32> = nfy.poll(ctx)
    if pcode == runtime.PollReady {
        this.pending_nf = null
        // Notify may have raced past the gen check above — re-read before Pending.
        hub.gate_lock.lock()
        cur2<i32> = hub.generation
        hub.gate_lock.unlock()
        if cur2 != this.arrival_gen {
            this.stage = 2
            return runtime.PollReady, this.leader_flag.(i64)
        }
    }
    return runtime.PollPending
}

// Cross-pkg factory: barrier bits → BarrierWaitFut.
fn barrier_wait_fut_bits(barrier_bits<u64>) BarrierWaitFut {
    b<Barrier> = barrier_bits.(Barrier)
    fut<BarrierWaitFut> = new BarrierWaitFut{}
    fut.init(b)
    return fut
}

// Leader flag after the future is Ready (also available as await result).
fn barrier_wait_leader_bits(fut_bits<u64>) i32 {
    f<BarrierWaitFut> = fut_bits.(BarrierWaitFut)
    return f.leader_flag
}
