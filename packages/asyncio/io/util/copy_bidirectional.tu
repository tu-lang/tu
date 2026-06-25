// Bidirectional pump: copy a -> b and b -> a until both halves see EOF.
// First-pass implementation runs the two directions sequentially (a -> b
// to completion, then b -> a) because select / join macros are not yet
// available. Once macros land, this should be rewritten to drive both
// directions concurrently. // TEMP: dynamic, will be replaced by static
// concurrent copy in task 19.x once select2/join2 macros land.

use runtime
use io as iobuf
use asyncio.io as aio
use asyncio.io.util as aiou

// Pump bytes a -> b then b -> a, returning (0, ab_total, ba_total) on
// clean EOF on both sides. On error from either direction the function
// short-circuits and returns whatever totals were observed so far.
async copy_bidirectional(a<u64>, b<u64>) (i32, u64, u64) {
    err_ab<i32>, ab<u64> = aiou.copy(a, b).await
    if err_ab != 0 return err_ab, ab, 0.(u64)
    err_ba<i32>, ba<u64> = aiou.copy(b, a).await
    if err_ba != 0 return err_ba, ab, ba
    return 0, ab, ba
}
