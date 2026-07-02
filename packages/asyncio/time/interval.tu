// Periodic timer built on the time wheel. tick() resolves once per period;
// missed_strategy decides how the schedule catches up after a slow tick.
// NOTE: spec/design describe `class Interval` embedding a sys.Duration; per
// library-static-only this is a static `mem` and stores the period as u64
// milliseconds to avoid value-embedding another mem.

use sys
use asyncio.runtime.time as rttime

// Missed-tick strategies.
BURST<i32> = 0   // stride by period; each missed tick fires back-to-back
SKIP<i32>  = 1   // drop missed ticks; realign to the next future deadline
DELAY<i32> = 2   // shift the schedule; next deadline = now + period

// Interval state. deadline_ms is the next tick's deadline in ms since the
// time source origin.
mem Interval {
    u64 period_ms          // tick spacing in milliseconds
    u64 deadline_ms        // next tick deadline (ms since origin)
    i32 missed_strategy    // BURST / SKIP / DELAY
}

// Current runtime clock in ms, or 0 when no runtime/time driver is active.
fn current_now_ms() u64 {
    th<rttime.TimeHandle> = current_time_handle()
    if th == null return 0
    return th.clock.now_ms()
}

// Build an Interval firing every `period`; first tick is one period out.
// Defaults to the Burst missed-tick strategy (tokio's default).
const interval(period<sys.Duration>) Interval {
    iv<Interval> = new Interval
    iv.period_ms       = period.as_millis()
    iv.missed_strategy = BURST
    iv.deadline_ms     = current_now_ms() + iv.period_ms
    return iv
}

// Move deadline_ms past the tick that just fired, honouring missed_strategy.
Interval::advance(){
    p<u64> = this.period_ms
    if this.missed_strategy == BURST {
        this.deadline_ms = this.deadline_ms + p
        return
    }
    now<u64> = current_now_ms()
    if this.missed_strategy == DELAY {
        this.deadline_ms = now + p
        return
    }
    // SKIP: jump to the first deadline strictly after `now`.
    next<u64> = this.deadline_ms + p
    if next <= now && p != 0 {
        behind<u64> = now - this.deadline_ms
        skips<u64>  = behind / p + 1
        next = this.deadline_ms + skips * p
    }
    this.deadline_ms = next
}

// Await the next tick. Returns (err, fired_instant) where err is io.Ok once
// the deadline fires. A fresh Sleep registers deadline_ms into the wheel;
// advance() then reschedules for the following tick.
async Interval::tick() (i32, rttime.Instant) {
    e<rttime.TimerEntry> = rttime.TimerEntry::new(this.deadline_ms)
    s<Sleep> = new Sleep { entry: e, registered: 0 }
    err<i32> = s.await
    fired<rttime.Instant> = rttime.Instant::now()
    this.advance()
    return err, fired
}
