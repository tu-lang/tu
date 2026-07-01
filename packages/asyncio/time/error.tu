// Timer error codes surfaced by asyncio.time, re-exported so callers stay
// within `use asyncio.time`.

use asyncio.error as aerr

// Deadline elapsed before the awaited future resolved (alias of the shared
// asyncio.error.Elapsed code).
Elapsed<i32> = aerr.Elapsed

// The time driver was shut down while a timer was still registered.
TimerShutdown<i32> = 0x03020010
