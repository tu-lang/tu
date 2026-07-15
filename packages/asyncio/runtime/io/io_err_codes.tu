// Library io error codes used by the IO driver.
// Mirrored as package locals so this package (short-name `io`) never
// `use io as libio` — that import registers path "io" and poisons
// getPackage for local mem types (Ready, ScheduledIo, …).
// Values match library/io/error.tu and library/io/async.tu.

IO_WOULD_BLOCK<i32>            = 16908302
IO_INTERRUPTED<i32>            = 16908324
IO_OTHER_DRIVER_TERMINATED<i32> = 50397243
