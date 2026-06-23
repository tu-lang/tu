//die;implement by asm
func die(code<i8>)

//time ; implement by asm
func time(t<u64>)

func clock_gettime(clockid<i64>,tp<u64*>)

//nanossleep ; implement by asm
func nanosleep(req<u64*>,rem<u64*>)

//brk ; implement by asm
func brk(brk<u64>)

//segsegv recv; implement by asm
func segsegvrecv()

//execv ; implement by asm
func execve(filename<i8*>,argv<i8*>,envp<i8*>)

func sigreturn()
//sig %rdi
//act %rsi
//oact %rdx
//size %r10
func rt_sigaction(sig<i32>,act<u64>,oact<u64>,size<u64>)

//sys_mmap	0x9
//@param addr  u64 %rdi
//@param len   u64 %rsi
//@param prot  u64 %rdx
//@param flags u64 %r10	
//@param fd	   u64 %r8
//@param off   u64 %r9
func mmap(addr<u64> , len<u64> , prot<u64> ,flags<u64>, fd<u64>,off<u64>)
//sys_madvise 28	
//@param start u64
//@param len_in	u64 
//@param behavior i32
func madvise(start<u64> , len_in<u64> , behavior<i32>)
//sys_munmap 11
//@param addr u64
//@param len u64
func munmap(addr<u64> , len<u64>)
//@return u64
fn   cputicks()
//@return u64
fn 	 gettid()

// Linux x86_64 syscall 289. fd=-1 creates a new signalfd; flags accept
// SFD_CLOEXEC | SFD_NONBLOCK. Returns new fd or -errno.
func signalfd4(fd<i32>, mask<u64>, sizemask<u64>, flags<i32>)

// Linux x86_64 syscall 14. how is SIG_BLOCK / SIG_UNBLOCK / SIG_SETMASK;
// set/oldset may be NULL.
func rt_sigprocmask(how<i32>, set<u64>, oldset<u64>, sigsetsize<u64>)

// Linux x86_64 syscall 434. flags supports 0 or PIDFD_NONBLOCK on current
// kernels. Returns new pidfd or -errno.
func pidfd_open(pid<i32>, flags<u32>)

// Linux x86_64 syscall 61. x86_64 has no dedicated waitpid syscall; libc's
// waitpid is wait4 with rusage=NULL. Returns reaped pid (>=0), 0 for WNOHANG
// with no exited child, or -errno.
func wait4(pid<i32>, status<u64>, options<i32>, rusage<u64>)

// Linux x86_64 syscall 57. Parent receives the child pid, child receives 0.
fn fork() (i64)

// Linux x86_64 syscall 33. Returns the new fd or -errno.
fn dup2(oldfd<i32>, newfd<i32>) (i32)

// Linux x86_64 syscall 293. fds is a length-2 i32 array [read_end, write_end];
// flags accept O_CLOEXEC | O_NONBLOCK. Returns 0 on success, -errno otherwise.
fn pipe2(fds<i32*>, flags<i32>) (i32)
