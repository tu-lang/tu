// Configuration block fed to schedulers + drivers at build time.
// Values are pre-resolved from Builder so the hot path never branches on
// "feature enabled?" — fields stay zero/null when a subsystem is off.

DEFAULT_GLOBAL_QUEUE_INTERVAL<u32> = 31
DEFAULT_EVENT_INTERVAL<u32>        = 61
DEFAULT_NEVENTS<u32>               = 1024

// Pre-built Config consumed by Builder::build_*.
mem Config {
    i32  disable_lifo_slot
    u32  global_queue_interval
    u32  event_interval
    u32  nevents
}

// Build a Config with Tokio-style defaults.
const Config::default() Config {
    return new Config {
        disable_lifo_slot:     0,
        global_queue_interval: DEFAULT_GLOBAL_QUEUE_INTERVAL,
        event_interval:        DEFAULT_EVENT_INTERVAL,
        nevents:               DEFAULT_NEVENTS,
    }
}

