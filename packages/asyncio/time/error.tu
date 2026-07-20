// Timer error codes surfaced by asyncio.time.
// Mother: tokio::time::error::{Elapsed, ...}.

// Deadline elapsed before the awaited future resolved.
// Same numeric code as asyncio.error.Elapsed.
Elapsed<i32> = 0x03020004

// The time driver was shut down while a timer was still registered.
TimerShutdown<i32> = 0x03020010
