// Bounded blocking thread pool. Workers wait on a runtime.Note used as a
// condvar surrogate; spawn enqueues an item and Wake's one worker. The
// num_notify counter prevents the classic lost-wakeup race.

use runtime
use std
use io
use asyncio.error as aerr

KEEP_ALIVE_SEC<u64> = 10
DEFAULT_QUEUE_DEPTH<u32> = 1024

// Shared queue + bookkeeping.
mem Shared {
    u64*           queue            // raw bits of BlockingTaskItem*; ring buffer
    u32            queue_head
    u32            queue_tail
    u32            queue_cap
    u32            num_notify       // pending wake credits
    i32            shutdown
    runtime.Note   condvar          // workers Sleep here; spawn / shutdown Wake
}

// Build empty Shared with the given capacity.
const Shared::new(queue_cap<u32>) Shared {
    s<Shared> = new Shared
    s.queue       = std.malloc(sizeof(u64) * queue_cap.(u64))
    s.queue_head  = 0
    s.queue_tail  = 0
    s.queue_cap   = queue_cap
    s.num_notify  = 0
    s.shutdown    = 0
    s.condvar.Clear()
    return s
}

// True when no items are queued.
Shared::is_empty() bool {
    if this.queue_head == this.queue_tail return true
    return false
}

// Append item bits at tail. Caller holds the pool's shared_lock.
Shared::push(item_bits<u64>) i32 {
    if (this.queue_tail - this.queue_head) >= this.queue_cap {
        return aerr.SendFull
    }
    idx<u32> = this.queue_tail & (this.queue_cap - 1)
    this.queue[idx] = item_bits
    this.queue_tail += 1
    return 0
}

// Pop head bits; returns (NotFound, 0) when empty.
Shared::pop() (i32, u64) {
    if this.queue_head == this.queue_tail return io.NotFound, 0
    idx<u32> = this.queue_head & (this.queue_cap - 1)
    bits<u64> = this.queue[idx]
    this.queue_head += 1
    return 0, bits
}

// The pool itself. Wraps Shared with the lock + worker bookkeeping.
mem BlockingPool {
    runtime.MutexInter shared_lock
    Shared*            shared
    u64                stack_size
    u32                thread_cap            // upper bound on workers
    u32                num_threads           // currently spawned
    u32                num_idle_threads      // currently parked on condvar
    u32                queue_depth
}

// Build a pool with default capacities.
const BlockingPool::new(thread_cap<u32>) BlockingPool {
    p<BlockingPool> = new BlockingPool
    p.shared_lock.init()
    p.shared           = Shared::new(DEFAULT_QUEUE_DEPTH)
    p.stack_size       = 0
    p.thread_cap       = thread_cap
    p.num_threads      = 0
    p.num_idle_threads = 0
    p.queue_depth      = DEFAULT_QUEUE_DEPTH
    return p
}

// Spawner is a thin handle over the pool, mirroring the runtime layout.
mem Spawner {
    BlockingPool* inner
}

// Build a Spawner around pool.
const Spawner::new(pool<BlockingPool>) Spawner {
    s<Spawner> = new Spawner
    s.inner = pool
    return s
}

// Module-level worker entry. runtime.newcore expects an (u64) entrypoint;
// we encode the BlockingPool* in that slot and dispatch from here.
ACTIVE_POOL<BlockingPool*> = null

fn blocking_worker_run(){
    p<BlockingPool> = ACTIVE_POOL
    if p == null return
    loop {
        p.shared_lock.lock()
        // Drain any pending item before checking shutdown so mandatory
        // items still run during the drain phase.
        loop {
            if p.shared.queue_head != p.shared.queue_tail break
            if p.shared.shutdown == 1 {
                p.shared_lock.unlock()
                return
            }
            p.num_idle_threads += 1
            p.shared_lock.unlock()
            p.shared.condvar.Sleep()
            p.shared.condvar.Clear()
            p.shared_lock.lock()
            p.num_idle_threads -= 1
        }
        err<i32>, bits<u64> = p.shared.pop()
        // Decrement notify credit when consuming a wake-up.
        if p.shared.num_notify > 0 {
            p.shared.num_notify -= 1
        }
        p.shared_lock.unlock()
        if err != 0 continue
        item<BlockingTaskItem> = bits.(BlockingTaskItem)
        if p.shared.shutdown == 1 && item.mandatory == 0 {
            // Non-mandatory items dropped during shutdown; the JoinHandle
            // observes a Cancelled outcome on its next poll.
            tk<BlockingTask> = item.task
            raw<task.RawTask> = tk.raw
            h<task.Header> = raw.hdr
            st<task.State> = h.state
            st.set_cancelled()
            task.wake_join_waker(raw)
            continue
        }
        item.task.run()
    }
}

// Submit one item. Returns 0 on success, RuntimeShutdown when shutdown is
// set and item is non-mandatory, SendFull when the queue is at capacity.
Spawner::spawn(item<BlockingTaskItem>) i32 {
    pool<BlockingPool> = this.inner
    pool.shared_lock.lock()
    if pool.shared.shutdown == 1 && item.mandatory == 0 {
        pool.shared_lock.unlock()
        return aerr.RuntimeShutdown
    }
    err<i32> = pool.shared.push(item.(u64))
    if err != 0 {
        pool.shared_lock.unlock()
        return err
    }
    // Spawn a fresh worker if all current workers are busy and we have
    // headroom under thread_cap.
    if pool.num_idle_threads == 0 && pool.num_threads < pool.thread_cap {
        ACTIVE_POOL = pool
        runtime.newcore(blocking_worker_run.(u64))
        pool.num_threads += 1
    }
    pool.shared.num_notify += 1
    pool.shared_lock.unlock()
    pool.shared.condvar.Wake()
    return 0
}

// Mandatory variant: fs / DNS / std-streams use this so shutdown still
// drains them.
Spawner::spawn_mandatory_blocking(item<BlockingTaskItem>) i32 {
    item.mandatory = 1
    return this.spawn(item)
}

// Mark the pool shut down and wake every worker so they observe the flag.
// Idempotent — second calls are no-ops.
BlockingPool::shutdown(){
    this.shared_lock.lock()
    if this.shared.shutdown == 1 {
        this.shared_lock.unlock()
        return
    }
    this.shared.shutdown = 1
    this.shared_lock.unlock()
    // Wake every worker; the Note condvar wakes one at a time so we loop.
    for i<u32> = 0 ; i < this.num_threads ; i += 1 {
        this.shared.condvar.Wake()
    }
}

