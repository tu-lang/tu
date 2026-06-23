// Process-related constants + waitpid wrapper around wait4 (Linux x86_64).
// O_CLOEXEC=0x80000 here matches pipe2(2)/socket(2) docs; it differs from
// the legacy 0x8000 in library/sys/syscode.tu.

WNOHANG<i32>    = 1
WUNTRACED<i32>  = 2
WCONTINUED<i32> = 8

PIDFD_NONBLOCK<u32> = 0x800

// libc-style waitpid: wait4(pid, status, options, NULL).
//@return >=0 reaped child pid, 0 = WNOHANG with no exited child, <0 = -errno
fn waitpid(pid<i32>, status<u64>, options<i32>) i32 {
    return wait4(pid, status, options, 0)
}

O_CLOEXEC<i32>  = 0x80000
O_NONBLOCK<i32> = 0x800
O_DIRECT<i32>   = 0x4000
