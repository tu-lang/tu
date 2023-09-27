//die;implement by asm
func die(code<i8>)

//time ; implement by asm
func time(t<u64>)

func clock_gettime(clockid<i64>,tp<u64*>)

//nanossleep ; implement by asm
func nanosleep(sec<u64>)

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
