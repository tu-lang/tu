// signalfd / sigset_t constants and helpers (Linux x86_64).
// Pairs with signalfd4 / rt_sigprocmask / rt_sigaction declared in sys.tu.

// signalfd4 flags
SFD_CLOEXEC<i32>  = 0x80000
SFD_NONBLOCK<i32> = 0x800

// rt_sigprocmask how
SIG_BLOCK<i32>    = 0
SIG_UNBLOCK<i32>  = 1
SIG_SETMASK<i32>  = 2

// 128-byte signalfd_siginfo record (read(signalfd) item).
mem SignalfdSiginfo {
    u32 ssi_signo
    i32 ssi_errno
    i32 ssi_code
    u32 ssi_pid
    u32 ssi_uid
    i32 ssi_fd
    u32 ssi_tid
    u32 ssi_band
    u32 ssi_overrun
    u32 ssi_trapno
    i32 ssi_status
    i32 ssi_int
    u64 ssi_ptr
    u64 ssi_utime
    u64 ssi_stime
    u64 ssi_addr
    u16 ssi_addr_lsb
    u16 _pad0
    u32 _pad1
    u64 _pad2
    u64 _pad3
    u64 _pad4
    u64 _pad5
    u64 _pad6
}

// signum is 1-based; out-of-range returns 0.
fn sigmask_bit(signum<i32>) u64 {
    if signum < 1 return 0
    return 1 << (signum - 1)
}

// On x86_64 sigset_t is a single 8-byte u64 bitmask.

fn sigemptyset(set<u64*>) {
    *set = 0
}

fn sigfullset(set<u64*>) {
    *set = 0xFFFFFFFFFFFFFFFF
}

// Returns 0 on success, -1 when signum is out of range.
fn sigaddset(set<u64*>, signum<i32>) i32 {
    if signum < 1 return -1
    if signum > 64 return -1
    *set = *set | sigmask_bit(signum)
    return 0
}

fn sigdelset(set<u64*>, signum<i32>) i32 {
    if signum < 1 return -1
    if signum > 64 return -1
    *set = *set & (~sigmask_bit(signum))
    return 0
}

// Returns 1=present, 0=absent, -1=out of range.
fn sigismember(set<u64*>, signum<i32>) i32 {
    if signum < 1 return -1
    if signum > 64 return -1
    if (*set & sigmask_bit(signum)) != 0 return 1
    return 0
}
