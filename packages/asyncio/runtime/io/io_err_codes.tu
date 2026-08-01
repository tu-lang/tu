// Library io error codes used by the IO driver.
// Package short-name is `io`; bare `use io` is safe after global full_package stamp.

use io

IO_WOULD_BLOCK<i32>             = io.WouldBlock
IO_INTERRUPTED<i32>             = io.Interrupted
IO_OTHER_DRIVER_TERMINATED<i32> = io.OtherDriverTerminated
