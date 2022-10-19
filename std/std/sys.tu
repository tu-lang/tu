//die;implement by asm
func die(code<i8>)

//time ; implement by asm
func time(t<u64>)

//sleep ; implement by asm
func sleep(sec<u64>)

//sleep ; implement by asm
func usleep(sec<u64>)

//brk ; implement by asm
func brk(brk<u64>)

//execv ; implement by asm
func execve(filename<i8*>,argv<i8*>,envp<i8*>)

func sigreturn()
//sig %rdi
//act %rsi
//oact %rdx
//size %r10
func rt_sigaction(sig<i32>,act<u64>,oact<u64>,size<u64>)