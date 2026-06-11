// Join-side error code aliases over asyncio.error.

use asyncio.error as aerr

JoinErrorCancelled<i32>        = aerr.Cancelled
JoinErrorAlreadyConsumed<i32>  = aerr.AlreadyConsumed
JoinErrorRuntimePollError<i32> = aerr.RuntimePollError
