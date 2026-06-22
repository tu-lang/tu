// WorkerCore + MtWorker layouts. WorkerCore is the per-worker mutable
// state (LIFO slot, run queue, Parker, FastRand). MtWorker wraps the
// worker's MtShared back-edge + the AtomicCell that lets block_in_place
// hand its core to a stand-in (deferred until Phase 10).

use util

// Per-worker mutable state. lifo_slot is one extra cache-line so a hot
// task can re-enter the worker without going through the Local FIFO.
mem WorkerCore {
    u32          tick
    u64          lifo_slot              // raw bits of RawTask*; 0 when empty
    i32          lifo_enabled           // 0/1
    Local*       run_queue
    i32          is_searching           // 0/1
    i32          is_shutdown            // 0/1
    Parker*      park
    FastRand*    rand
    u32          global_queue_interval
}

// Build a WorkerCore wired to run_queue + park.
const WorkerCore::new(run_queue<Local>, park<Parker>, rand<FastRand>, global_interval<u32>) WorkerCore {
    c<WorkerCore> = new WorkerCore
    c.tick                  = 0
    c.lifo_slot             = 0
    c.lifo_enabled          = 1
    c.run_queue             = run_queue
    c.is_searching          = 0
    c.is_shutdown           = 0
    c.park                  = park
    c.rand                  = rand
    c.global_queue_interval = global_interval
    return c
}

// MtWorker sits on a worker thread's stack-equivalent and owns the
// AtomicCell that surrenders core to other threads if needed.
mem MtWorker {
    MtHandle*    handle
    u32          index
    AtomicCell*  core      // single-slot u64 for WorkerCore* hand-off
}

// Build a worker for the given index.
const MtWorker::new(handle<MtHandle>, index<u32>, core<WorkerCore>) MtWorker {
    w<MtWorker> = new MtWorker
    w.handle = handle
    w.index  = index
    w.core   = AtomicCell::new(core.(u64))
    return w
}

