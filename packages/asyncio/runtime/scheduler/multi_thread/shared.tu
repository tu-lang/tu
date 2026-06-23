// Shared state every worker holds a pointer into. Owns the per-worker
// Steal half-handles (so foreign workers can drain remote queues), the
// inject queue, the OwnedTasks tracker, and the Idle / IdleSynced pair.

use runtime
use asyncio.task

// One slot per worker exposing its Steal end + Unparker.
mem Remote {
    Steal*    steal
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
    runtime.MutexInter synced_lock
    MtSynced*         synced
    runtime.MutexInter shutdown_cores_lock
    u64*              shutdown_cores       // raw bits of WorkerCore*; len == num_workers
    u32               shutdown_cores_len
}

// Allocate empty MtShared sized for num_workers. remotes are filled in
// later when each worker's queue is created.
const MtShared::new(num_workers<u32>) MtShared {
    s<MtShared> = new MtShared
    s.remotes     = std.malloc(sizeof(u64) * num_workers.(u64))
    s.num_workers = num_workers
    s.inject      = Inject::new()
    idle_pair_a<Idle>, idle_pair_b<IdleSynced> = idle_new(num_workers)
    s.idle        = idle_pair_a
    s.owned       = task.OwnedTasks::new()
    s.synced_lock.init()
    sn<MtSynced> = new MtSynced
    sn.idle_synced = idle_pair_b
    s.synced      = sn
    s.shutdown_cores_lock.init()
    s.shutdown_cores     = std.malloc(sizeof(u64) * num_workers.(u64))
    s.shutdown_cores_len = 0
    return s
}

