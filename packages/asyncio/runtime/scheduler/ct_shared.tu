// Cross-call-face state shared by every CtHandle clone. Owns the inject
// queue, OwnedTasks tracker, and the wakeup Notify the IO/blocking sides
// use to nudge the main thread out of park.

use asyncio.sync as libsync
use asyncio.task

// Shared state behind the Handle. driver / blocking_spawner are kept as
// u64 raw bits because the runtime root types (driver.Handle, blocking
// spawner) have not landed yet; build_current_thread will fill them in.
// Field names avoid `io_*` — outer `.io_drv` parses as a type assertion.
mem CtShared {
    Inject*           inject
    task.OwnedTasks*  owned
    u64          woken           // Notify* bits; use notify_*_raw bridges
    u64          driver             // raw bits of runtime.driver.Driver*
    u64          driver_handle      // raw bits of runtime.driver.DriverHandle*
    u64          iod_bits           // raw bits of IoDriver*
    u64          ioh_bits           // raw bits of IoHandle*
    u64          blocking_spawner   // raw bits of runtime.blocking.Spawner*
    u64          config             // raw bits of runtime.Config*
}

// Build empty shared state (no driver / blocking spawner wired yet).
const CtShared::new() CtShared {
    s<CtShared> = new CtShared
    s.inject           = Inject::new()
    s.owned            = task.OwnedTasks::new()
    s.woken            = libsync.notify_new_raw()
    s.driver           = 0
    s.driver_handle    = 0
    s.iod_bits         = 0
    s.ioh_bits         = 0
    s.blocking_spawner = 0
    s.config           = 0
    return s
}
