// Process-related constants and lightweight wrappers (Linux x86_64)
// Related: packages-asyncio-runtime task 1.3, R44.4, R44.5, R44.6
// Same package as std: provides wait/pidfd constants plus a waitpid wrapper,
// to be used with wait4 / pidfd_open declared in sys.tu.

// wait4 / waitpid options
WNOHANG<i32>    = 1
WUNTRACED<i32>  = 2
WCONTINUED<i32> = 8

// pidfd_open flags (PIDFD_NONBLOCK requires Linux >= 5.10)
PIDFD_NONBLOCK<u32> = 0x800

// waitpid(pid, status, options) is libc's wrapper around wait4(pid, status, options, NULL).
// x86_64 has no dedicated waitpid syscall, so we always go through wait4 with rusage=0.
//@param pid     pid to wait on (>0 specific pid, -1 any child, 0 same pgid, <-1 specific pgid)
//@param status  pointer to i32 status output, may be NULL (0)
//@param options WNOHANG etc
//@return >=0 reaped child pid, 0 means WNOHANG with no exited child, <0 -errno
fn waitpid(pid<i32>, status<u64>, options<i32>) i32 {
    return wait4(pid, status, options, 0)
}

// fd flags shared by pipe2 / dup2 / open (Linux x86_64).
// Related: packages-asyncio-runtime task 1.5, R44.4, R44.7
// Note: differs from library/sys/syscode.tu where O_CLOEXEC=0x8000 (legacy value).
// pipe2(2)/socket(2) and other newer interfaces document O_CLOEXEC=0x80000.
// Std exposes its own constants here; asyncio.process / netio etc. should `use std`.
O_CLOEXEC<i32>  = 0x80000
O_NONBLOCK<i32> = 0x800
O_DIRECT<i32>   = 0x4000
