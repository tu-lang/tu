// signalfd-related constants and data structures (Linux x86_64)
// Related: packages-asyncio-runtime task 1.2, R31.1, R31.2
// Same package as std: provides constants and SignalfdSiginfo,
// to be used with signalfd4 / rt_sigprocmask declared in sys.tu.

// signalfd4 flags
SFD_CLOEXEC<i32>  = 0x80000
SFD_NONBLOCK<i32> = 0x800

// rt_sigprocmask how
SIG_BLOCK<i32>    = 0
SIG_UNBLOCK<i32>  = 1
SIG_SETMASK<i32>  = 2

// signalfd_siginfo(7): read(signalfd) returns 128-byte records,
// fields ordered to match the kernel layout.
mem SignalfdSiginfo {
    u32 ssi_signo       // signal number that was raised
    i32 ssi_errno
    i32 ssi_code
    u32 ssi_pid         // sender pid (kill/sigqueue)
    u32 ssi_uid         // sender uid
    i32 ssi_fd          // fd that triggered SIGIO/SIGPOLL
    u32 ssi_tid
    u32 ssi_band
    u32 ssi_overrun
    u32 ssi_trapno
    i32 ssi_status      // wait status for SIGCHLD
    i32 ssi_int
    u64 ssi_ptr
    u64 ssi_utime
    u64 ssi_stime
    u64 ssi_addr
    u16 ssi_addr_lsb
    // padding up to 128 bytes
    u16 _pad0
    u32 _pad1
    u64 _pad2
    u64 _pad3
    u64 _pad4
    u64 _pad5
    u64 _pad6
}

// Compute the bit in sigset_t corresponding to signum (signum is 1-based)
fn sigmask_bit(signum<i32>) u64 {
    if signum < 1 return 0
    return 1.(u64) << ((signum - 1).(u64))
}

// sigset_t user-space helpers: on x86_64 sigset_t is a single 8-byte u64 bitmask.
// Related: packages-asyncio-runtime task 1.4, R31.4
// Companion to std.rt_sigaction / std.rt_sigprocmask / std.signalfd4.

// sigemptyset(set): clear all bits
fn sigemptyset(set<u64*>) {
    *set = 0
}

// sigfullset(set): set every bit (kernel will silently ignore SIGKILL/SIGSTOP)
fn sigfullset(set<u64*>) {
    *set = 0xFFFFFFFFFFFFFFFF
}

// sigaddset(set, signum): set the bit corresponding to signum
//@return 0 on success, -1 if signum is out of range
fn sigaddset(set<u64*>, signum<i32>) i32 {
    if signum < 1 return -1
    if signum > 64 return -1
    *set = *set | sigmask_bit(signum)
    return 0
}

// sigdelset(set, signum): clear the bit corresponding to signum
//@return 0 on success, -1 if signum is out of range
fn sigdelset(set<u64*>, signum<i32>) i32 {
    if signum < 1 return -1
    if signum > 64 return -1
    *set = *set & (~sigmask_bit(signum))
    return 0
}

// sigismember(set, signum): test whether signum is in set
//@return 1 = present, 0 = absent, -1 = signum out of range
fn sigismember(set<u64*>, signum<i32>) i32 {
    if signum < 1 return -1
    if signum > 64 return -1
    if (*set & sigmask_bit(signum)) != 0 return 1
    return 0
}
