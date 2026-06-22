// Wake-once / wake-all primitive backed by an intrusive waiter list.
//   notify_one()       — wake the queue head, or stash one permit when empty.
//   notify_waiters()   — wake every currently-queued waiter (no permit).
//   await notified()   — yield until either a wake hits us or a permit was
//                        already pending.

use runtime
use util

// notify_one permit accounting. Only NONE and ONE are used today; the
// ALL flag is reserved for a future "broadcast" extension.
NOTIFY_NONE<i32> = 0
NOTIFY_ONE<i32>  = 1
NOTIFY_ALL<i32>  = 2

// Notified future stages. 0 = before first poll, 1 = queued, 2 = done.
NOTIFIED_STAGE_INIT<i32>    = 0
NOTIFIED_STAGE_WAITING<i32> = 1
NOTIFIED_STAGE_DONE<i32>    = 2

// One queued waiter; placed on Notify.waiters via the embedded Pointers.
mem NotifyWaiter {
    Pointers node           // intrusive prev/next; offset 0
    u64      ctx_packed     // (sched, task_id) the wake side schedules
    i32      notified       // monotonic 0 -> 1 once dequeued by a wake
}

// Build a fresh waiter ready to be linked. `new NotifyWaiter` returns the
// heap pointer; pass it through (no `&`).
const NotifyWaiter::new(ctx<u64>) NotifyWaiter {
    w<NotifyWaiter> = new NotifyWaiter
    w.node.prev   = null
    w.node.next   = null
    w.ctx_packed  = ctx
    w.notified    = 0
    return w
}

// Notify itself. waiters is the queue of pending Notified futures; state
// holds at most one queued permit when no waiter is around to consume it.
mem Notify {
    runtime.MutexInter lock
    i32                state    // permit slot; only NONE / ONE used
    LinkedList*        waiters
}

// Build an empty Notify in the NOTIFY_NONE state.
const Notify::new() Notify {
    n<Notify> = new Notify
    n.lock.init()
    n.state   = NOTIFY_NONE
    n.waiters = LinkedList::new()
    return n
}

// Hand off to one waiter, or stash a single permit when none are queued.
// Returns NOTIFY_ONE when a permit was stashed, NOTIFY_NONE when a waiter
// was woken (the wake itself happens after the lock drops).
Notify::notify_one() i32 {
    this.lock.lock()
    head_node<Pointers> = this.waiters.head
    if head_node == null {
        if this.state == NOTIFY_NONE this.state = NOTIFY_ONE
        this.lock.unlock()
        return NOTIFY_ONE
    }
    this.waiters.remove(head_node)
    w<NotifyWaiter> = head_node.(NotifyWaiter)
    w.notified = 1
    this.lock.unlock()
    // ctx_packed is consumed by the runtime root once it lands; for now
    // we leave the waiter flagged and rely on the future's own poll to
    // observe `notified == 1` and resolve.
    return NOTIFY_NONE
}

// Wake every currently queued waiter; does NOT stash a permit. Waiters
// added after this call wait for the next notify.
Notify::notify_waiters(){
    this.lock.lock()
    loop {
        h<Pointers> = this.waiters.head
        if h == null break
        this.waiters.remove(h)
        w<NotifyWaiter> = h.(NotifyWaiter)
        w.notified = 1
    }
    this.lock.unlock()
}

// Async leaf future returned by Notify::notified().
mem Notified: async {
    Notify*        parent
    i32            stage   // NOTIFIED_STAGE_*
    NotifyWaiter*  node    // null until first poll links us
}

// Initialise the future before the first poll.
Notified::init(parent<Notify>){
    this.parent = parent
    this.stage  = NOTIFIED_STAGE_INIT
    this.node   = null
}

// Three-stage state machine. INIT consumes a stashed permit if available;
// WAITING checks the wake flag; DONE re-poll is a logic error.
Notified::poll(ctx){
    parent<Notify> = this.parent
    if this.stage == NOTIFIED_STAGE_INIT {
        parent.lock.lock()
        if parent.state == NOTIFY_ONE {
            parent.state = NOTIFY_NONE
            parent.lock.unlock()
            this.stage = NOTIFIED_STAGE_DONE
            return runtime.PollReady, 0
        }
        // No permit; queue ourselves.
        w<NotifyWaiter> = NotifyWaiter::new(ctx.(u64))
        parent.waiters.push_back(&w.node)
        parent.lock.unlock()
        this.node  = w
        this.stage = NOTIFIED_STAGE_WAITING
        return runtime.PollPending
    }
    if this.stage == NOTIFIED_STAGE_WAITING {
        n<NotifyWaiter> = this.node
        if n.notified == 1 {
            this.stage = NOTIFIED_STAGE_DONE
            return runtime.PollReady, 0
        }
        // Refresh ctx so the most recent waker wins.
        n.ctx_packed = ctx.(u64)
        return runtime.PollPending
    }
    // Already DONE; behaves like AlreadyConsumed.
    return runtime.PollReady, 0
}

// Public entry point. Builds the future; caller must `await` it.
async Notify::notified(){
    fut<Notified> = new Notified
    fut.init(this)
    code<i32> = fut.await
    return code
}

