// Task error code aliases
// Related: packages-asyncio-runtime task 3.30, R8.6
//
// All join-side error paths share a single set of codes so callers do not
// have to reach into asyncio.error directly.  The numeric values come from
// asyncio.error (task 20.1).

use asyncio.error as aerr

JoinErrorCancelled<i32>       = aerr.Cancelled
JoinErrorAlreadyConsumed<i32> = aerr.AlreadyConsumed
JoinErrorRuntimePollError<i32> = aerr.RuntimePollError
