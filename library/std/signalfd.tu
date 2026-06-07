// signalfd 相关常量与数据结构（Linux x86_64）
// 关联：packages-asyncio-runtime task 1.2，R31.1, R31.2
// 与 std 同包：本文件提供常量与 SignalfdSiginfo 结构，配合 sys.tu 中的 signalfd4 / rt_sigprocmask 使用

// signalfd4 flags
SFD_CLOEXEC<i32>  = 0x80000
SFD_NONBLOCK<i32> = 0x800

// rt_sigprocmask how
SIG_BLOCK<i32>    = 0
SIG_UNBLOCK<i32>  = 1
SIG_SETMASK<i32>  = 2

// signalfd_siginfo(7)：read(signalfd) 每条记录 128 字节，字段顺序与内核一致
mem SignalfdSiginfo {
    u32 ssi_signo       // 触发的信号编号
    i32 ssi_errno
    i32 ssi_code
    u32 ssi_pid         // 发送方 pid（kill/sigqueue）
    u32 ssi_uid         // 发送方 uid
    i32 ssi_fd          // SIGIO/SIGPOLL 的 fd
    u32 ssi_tid
    u32 ssi_band
    u32 ssi_overrun
    u32 ssi_trapno
    i32 ssi_status      // SIGCHLD 的 wait status
    i32 ssi_int
    u64 ssi_ptr
    u64 ssi_utime
    u64 ssi_stime
    u64 ssi_addr
    u16 ssi_addr_lsb
    // padding 至 128 字节
    u16 _pad0
    u32 _pad1
    u64 _pad2
    u64 _pad3
    u64 _pad4
    u64 _pad5
    u64 _pad6
}

// 计算 sigset_t 中某 signum 对应的位（signum 从 1 起）
fn sigmask_bit(signum<i32>) u64 {
    if signum < 1 return 0
    return 1.(u64) << ((signum - 1).(u64))
}
