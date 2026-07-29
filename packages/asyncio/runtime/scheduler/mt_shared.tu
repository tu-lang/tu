// Shared state every worker holds a pointer into. Owns the per-worker
// Steal half-handles (so foreign workers can drain remote queues), the
// inject queue, the OwnedTasks tracker, and the Idle / IdleSynced pair.

use runtime
use std
use asyncio.task

// One slot per worker exposing its Steal end + Unparker.
mem Remote {
    Steal*    steal_end
    Unparker* unparker
}

// MtSynced bundles fields guarded by `synced_lock`.
mem MtSynced {
    IdleSynced*  idle_synced
    // Future fields: shutdown counter, etc.
}

// Cross-worker shared state.
mem MtShared {
    u64*              remotes              // raw bits of Remote*; length num_workers
    u32               num_workers
    Inject*           inject
    Idle*             idle
    task.OwnedTasks*  owned
    runtime.MutexInter* synced_lock
    MtSynced*         lock_hub
    runtime.MutexInter* shutdown_cores_lock
    u64*              shutdown_cores       // raw bits of WorkerCore*; len == num_workers
    u32               shutdown_cores_len
    u64               block_on_root_bits   // RawTask* of block_on root; 0 = none
    Unparker*         block_on_unparker    // wakes block_on caller
    i32               shutting_down        // 1 after inject close; park loops exit
    i32               workers_alive        // OS threads still in worker_entry
    ParkDriverHub*    park_hub             // shared driver TryLock for PARKED_DRIVER
}

// Allocate empty MtShared sized for num_workers. remotes are filled in
// later when each worker's queue is created.
const MtShared::new(num_workers<u32>) MtShared {
    s<MtShared> = new MtShared
    nw<u64> = num_workers.(u64)
    bytes<u64> = 8 * nw
    s.remotes     = std.malloc(bytes)
    s.num_workers = num_workers
    s.inject      = Inject::new()
    idle_pair_a<Idle>, idle_pair_b<IdleSynced> = idle_new(num_workers)
    s.idle        = idle_pair_a
    s.owned       = task.OwnedTasks::new()
    s.synced_lock = new runtime.MutexInter
    s.synced_lock.init()
    sn<MtSynced> = new MtSynced
    sn.idle_synced = idle_pair_b
    s.lock_hub      = sn
    s.shutdown_cores_lock = new runtime.MutexInter
    s.shutdown_cores_lock.init()
    s.shutdown_cores     = std.malloc(bytes)
    s.shutdown_cores_len = 0
    s.block_on_root_bits = 0
    s.block_on_unparker  = null
    s.shutting_down      = 0
    s.workers_alive      = 0
    s.park_hub           = null
    return s
}

