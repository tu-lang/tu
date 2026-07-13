// FIFO multi-permit semaphore. Backbone for Mutex / RwLock / Semaphore /
// MPSC's bounded channel. release(n) feeds the head waiter first; if the
// head needs more permits than `n` we stop, leaving the head still queued
// so smaller release calls cannot starve a large request.

use runtime

// Cap on `permits`; we leave the high three bits unused so encoding tricks
// (e.g. embedding a "shutdown_flag" sentinel) stay available later.
MAX_PERMITS<u32> = 0x1FFFFFFF

CLOSED_FLAG<i32> = 1
SEM_ERR_CLOSED<i32> = 0x03020002
SEM_ERR_SENDFULL<i32> = 0x0302000A

// One queued waiter; remaining_permits drops as release feeds it.
mem SemWaiter {
    Pointers node             // intrusive prev/next; offset 0
    u32      remaining_permits  // permits still owed before wake
    u64      ctx_packed         // scheduler ctx
    i32      queued             // monotonic 0 -> 1 once linked
}

// Build a fresh waiter that needs n permits.
const SemWaiter::new(n<u32>, ctx<u64>) SemWaiter {
    w<SemWaiter> = new SemWaiter
    w.node.prev   = null
    w.node.next   = null
    w.remaining_permits = n
    w.ctx_packed  = ctx
    w.queued      = 0
    return w
}

// Counting semaphore with FIFO fairness.
mem BatchSemaphore {
    u32         permits     // free permits (must read under lock when waiters present)
    runtime.MutexInter* lock
    LinkedList* waiters     // FIFO of SemWaiter
    i32         shutdown_flag      // 0 / CLOSED_FLAG
}

// Build with `n` initial permits. n must be <= MAX_PERMITS.
const BatchSemaphore::new(n<u32>) BatchSemaphore {
    s<BatchSemaphore> = new BatchSemaphore
    s.permits = n
    s.lock = new runtime.MutexInter
    s.lock.init()
    s.waiters = LinkedList::new()
    s.shutdown_flag  = 0
    return s
}

// Non-blocking acquire. Returns 0 on success, asyncio.error.SendFull when
// not enough permits are available, asyncio.error.Closed when shut down.
BatchSemaphore::try_acquire(n<u32>) i32 {
    this.lock.lock()
    if this.shutdown_flag == CLOSED_FLAG {
        this.lock.unlock()
        return SEM_ERR_CLOSED
    }
    if this.permits >= n {
        this.permits -= n
        this.lock.unlock()
        return 0
    }
    this.lock.unlock()
    return SEM_ERR_SENDFULL
}

// Add `n` permits and feed the FIFO. Stops at the first head waiter that
// still needs more than the available pool, preserving fairness.
BatchSemaphore::release(n<u32>){
    this.lock.lock()
    pool<u32> = this.permits + n
    loop {
        h<Pointers> = this.waiters.peek_head()
        if h == null break
        w<SemWaiter> = h.(SemWaiter)
        if w.remaining_permits > pool break
        // Feed the head; pool drains by remaining_permits, the head wakes.
        pool = pool - w.remaining_permits
        w.remaining_permits = 0
        this.waiters.remove(h)
        w.queued = 0
        // Wake observation: subsequent poll sees remaining_permits == 0
        // and resolves; the runtime root will route ctx into the
        // scheduler queue once it lands.
    }
    this.permits = pool
    this.lock.unlock()
}

// Mark shutdown_flag and surface Closed to every waiter. Idempotent.
BatchSemaphore::close(){
    this.lock.lock()
    this.shutdown_flag = CLOSED_FLAG
    loop {
        h<Pointers> = this.waiters.peek_head()
        if h == null break
        w<SemWaiter> = h.(SemWaiter)
        this.waiters.remove(h)
        w.queued = 0
        // Setting remaining_permits to MAX_PERMITS+1 acts as a "shutdown_flag"
        // sentinel observed by the future's poll; it short-circuits to
        // asyncio.error.Closed.
        w.remaining_permits = MAX_PERMITS + 1
    }
    this.lock.unlock()
}

// Async future variant of try_acquire. Stages:
//   0 = INIT       — fast path; success short-circuits, otherwise queue.
//   1 = WAITING    — observe remaining_permits / shutdown_flag flag.
//   2 = DONE.
ACQ_STAGE_INIT<i32>    = 0
ACQ_STAGE_WAITING<i32> = 1
ACQ_STAGE_DONE<i32>    = 2

// Async leaf used by acquire().
mem AcquireFut: async {
    BatchSemaphore* owner_sem   // tokio: parent semaphore
    u32             needed
    i32             stage
    SemWaiter*      waiter_node
}

// Initialise the future for `n` permits.
AcquireFut::init(sem<BatchSemaphore>, n<u32>){
    this.owner_sem = sem
    this.needed = n
    this.stage  = ACQ_STAGE_INIT
    this.waiter_node   = null
}

// Poll the future; returns (PollReady, 0) on success, (PollReady, err)
// on close, (PollPending, 0) when still waiting.
AcquireFut::poll(ctx){
    sem<BatchSemaphore> = this.owner_sem

    if this.stage == ACQ_STAGE_INIT {
        sem.lock.lock()
        if sem.shutdown_flag == CLOSED_FLAG {
            sem.lock.unlock()
            this.stage = ACQ_STAGE_DONE
            return runtime.PollReady, SEM_ERR_CLOSED
        }
        if sem.waiters.is_empty() != 0 && sem.permits >= this.needed {
            sem.permits -= this.needed
            sem.lock.unlock()
            this.stage = ACQ_STAGE_DONE
            return runtime.PollReady, 0
        }
        w<SemWaiter> = SemWaiter::new(this.needed, ctx.(u64))
        sem.waiters.push_back(w.node)
        w.queued = 1
        sem.lock.unlock()
        this.waiter_node  = w
        this.stage = ACQ_STAGE_WAITING
        return runtime.PollPending
    }

    if this.stage == ACQ_STAGE_WAITING {
        n<SemWaiter> = this.waiter_node
        if n.remaining_permits == 0 {
            this.stage = ACQ_STAGE_DONE
            return runtime.PollReady, 0
        }
        if n.remaining_permits > MAX_PERMITS {
            this.stage = ACQ_STAGE_DONE
            return runtime.PollReady, SEM_ERR_CLOSED
        }
        n.ctx_packed = ctx.(u64)
        return runtime.PollPending
    }
    return runtime.PollReady, 0
}

// Public async entry: returns 0 on success, asyncio.error.Closed on close.
async BatchSemaphore::acquire(n<u32>){
    fut<AcquireFut> = new AcquireFut
    fut.init(this, n)
    return fut.await
}

// Cross-package bridges: BatchSemaphore heap pointer stored as u64.
fn batch_sem_new_raw(n<u32>) u64 {
    s<BatchSemaphore> = BatchSemaphore::new(n)
    return s.(u64)
}

fn batch_sem_try_acquire_raw(bits<u64>, n<u32>) i32 {
    s<BatchSemaphore> = bits.(BatchSemaphore)
    return s.try_acquire(n)
}

fn batch_sem_release_raw(bits<u64>, n<u32>) {
    s<BatchSemaphore> = bits.(BatchSemaphore)
    s.release(n)
}

fn batch_sem_close_raw(bits<u64>) {
    s<BatchSemaphore> = bits.(BatchSemaphore)
    s.close()
}

fn batch_sem_acquire_fut(bits<u64>, n<u32>) AcquireFut {
    fut<AcquireFut> = new AcquireFut
    fut.init(bits.(BatchSemaphore), n)
    return fut
}

fn batch_sem_acquire_fut_raw(bits<u64>, n<u32>) u64 {
    fut<AcquireFut> = batch_sem_acquire_fut(bits, n)
    return fut.(u64)
}

// Same-package helper to avoid Permit::give_back / guard method name clashes
// with BatchSemaphore::release member calls.
fn batch_sem_release(sem<BatchSemaphore>, n<u32>) {
    sem.release(n)
}

