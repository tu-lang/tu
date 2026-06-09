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

//signalfd4 ; implement by asm
//@param fd        i32 %rdi   -1 means create a new signalfd
//@param mask      u64 %rsi   pointer to sigset_t
//@param sizemask  u64 %rdx   size of sigset_t (typically 8)
//@param flags     i32 %r10   SFD_CLOEXEC | SFD_NONBLOCK
//@return new signalfd fd or negative errno
func signalfd4(fd<i32>, mask<u64>, sizemask<u64>, flags<i32>)

//rt_sigprocmask ; implement by asm
//@param how       i32 %rdi   SIG_BLOCK / SIG_UNBLOCK / SIG_SETMASK
//@param set       u64 %rsi   new mask pointer; NULL = query only
//@param oldset    u64 %rdx   old mask output pointer; NULL = don't need it
//@param sigsetsize u64 %r10  size of sigset_t (typically 8)
func rt_sigprocmask(how<i32>, set<u64>, oldset<u64>, sigsetsize<u64>)

//pidfd_open ; implement by asm
//@param pid    i32 %rdi   target process pid
//@param flags  u32 %rsi   PIDFD_NONBLOCK etc; current kernel only supports 0 or PIDFD_NONBLOCK
//@return new pidfd or negative errno
//Linux x86_64 syscall 434
func pidfd_open(pid<i32>, flags<u32>)

//wait4 ; implement by asm
//x86_64 has no dedicated waitpid syscall: waitpid(pid,status,options) is wait4(pid,status,options,NULL)
//@param pid     i32 %rdi   target pid (>0 specific pid, -1 any child, 0 same pgid, <-1 specific pgid)
//@param status  u64 %rsi   pointer to i32 status output, may be NULL
//@param options i32 %rdx   WNOHANG / WUNTRACED / WCONTINUED etc
//@param rusage  u64 %r10   pointer to rusage, NULL means not needed
//@return >=0 reaped child pid, 0 means WNOHANG with no exited child, <0 -errno
//Linux x86_64 syscall 61
func wait4(pid<i32>, status<u64>, options<i32>, rusage<u64>)

//fork ; implement by asm
//Linux x86_64 syscall 57
//@return >=0: parent receives child pid, child receives 0; <0: -errno
fn fork() i64

//dup2 ; implement by asm
//@param oldfd  i32 %rdi
//@param newfd  i32 %rsi
//Linux x86_64 syscall 33
//@return new fd or -errno
fn dup2(oldfd<i32>, newfd<i32>) i32

//pipe2 ; implement by asm
//@param fds<i32*>  %rdi   length-2 i32 array: [read_end, write_end]
//@param flags<i32> %rsi   O_CLOEXEC | O_NONBLOCK etc
//Linux x86_64 syscall 293
//@return 0 on success, <0 -errno
fn pipe2(fds<i32*>, flags<i32>) i32
