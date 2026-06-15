// Pause / advance shim for tests. Production code constructs a Clock with
// paused=0 and now_ms simply forwards to TimeSource. Test code can pause
// the clock and step it forward via advance_ms; resume snaps back to the
// underlying source without skipping forward.

use sys

// Wall-clock view layered over TimeSource.
mem Clock {
    TimeSource* src
    i32 paused           // 0 = follow TimeSource, 1 = use frozen_ms + advanced
    u64 frozen_ms        // base ms captured at pause()
    u64 advanced_ms      // delta added by advance() while paused
}

// Build a Clock that follows src directly.
const Clock::new(src<TimeSource>) Clock* {
    c<Clock> = new Clock
    c.src           = src
    c.paused        = 0
    c.frozen_ms     = 0
    c.advanced_ms   = 0
    return &c
}

// Freeze time at the current ms reading; subsequent now_ms calls observe
// only the explicit advance() bumps until resume().
Clock::pause(){
    if this.paused == 1 return
    this.frozen_ms   = this.src.now_ms()
    this.advanced_ms = 0
    this.paused      = 1
}

// Resume real time; the clock snaps to the live source so timers do not
// see a backward step. Any pending advance is discarded.
Clock::resume(){
    if this.paused == 0 return
    this.paused      = 0
    this.frozen_ms   = 0
    this.advanced_ms = 0
}

// Advance the frozen clock by d. Only meaningful while paused.
Clock::advance(d<sys.Duration>){
    if this.paused == 0 return
    ns_part<u64> = d.nanos.inner.(u64)
    this.advanced_ms += d.secs * 1000 + ns_part / 1000000
}

// Current ms reading. Frozen when paused; live otherwise.
Clock::now_ms() u64 {
    if this.paused == 1 return this.frozen_ms + this.advanced_ms
    return this.src.now_ms()
}

