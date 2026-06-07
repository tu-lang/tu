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
//@param fd        i32 %rdi   -1 表示新建 signalfd
//@param mask      u64 %rsi   指向 sigset_t 的指针
//@param sizemask  u64 %rdx   sigset_t 大小（一般为 8）
//@param flags     i32 %r10   SFD_CLOEXEC | SFD_NONBLOCK
//@return new signalfd fd or negative errno
func signalfd4(fd<i32>, mask<u64>, sizemask<u64>, flags<i32>)

//rt_sigprocmask ; implement by asm
//@param how       i32 %rdi   SIG_BLOCK / SIG_UNBLOCK / SIG_SETMASK
//@param set       u64 %rsi   新 mask 指针；NULL 时仅查询
//@param oldset    u64 %rdx   旧 mask 输出指针；NULL 表示不需要
//@param sigsetsize u64 %r10  sigset_t 大小（一般为 8）
func rt_sigprocmask(how<i32>, set<u64>, oldset<u64>, sigsetsize<u64>)
