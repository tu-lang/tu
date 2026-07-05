// pidfd-based child reaper (tokio's preferred wait path on Linux >= 5.3).
//
// Design note (task 17.3): open() acquires a pidfd; wait() would register the
// pidfd for read-readiness on the IO driver and reap once it fires. V1: the
// readiness path is not wired, so wait() blocks in waitpid on the pid. When
// pidfd_open is unavailable open() returns an error so callers fall back to
// SigchldReaper.

use runtime
use io
use std
use sys

// Holds an open pidfd plus the pid it refers to.
mem PidfdReaper {
    i32 pidfd
    i32 pid
}

// Open a pidfd for `pid`. Returns (io.Ok, reaper) or (err, null) when
// pidfd_open is unavailable (fall back to SigchldReaper).
const PidfdReaper::open(pid<i32>) (i32, PidfdReaper) {
    err<i32>, fd<u64> = sys.cvt(std.pidfd_open(pid, 0))
    if err != io.Ok return err, null
    return io.Ok, new PidfdReaper { pidfd: fd.(i32), pid: pid }
}

// The raw pidfd, for read-readiness registration once the IO driver is wired.
PidfdReaper::as_raw_fd() i32 {
    return this.pidfd
}

// Wait for the child to exit and return its ExitStatus. V1: blocking waitpid;
// the pidfd-readiness await path lands with the IO driver.
async PidfdReaper::wait() i32, ExitStatus {
    status<i32> = 0
    r<i32> = std.waitpid(this.pid, (&status).(u64), 0)
    if r < 0 return io.Other, null
    return io.Ok, exit_status_from_wait(status)
}

// Close the pidfd.
PidfdReaper::close() i32 {
    e<i32> = close_fd(this.pidfd)
    this.pidfd = -1
    return e
}
