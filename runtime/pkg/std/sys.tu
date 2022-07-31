//die;implement by asm
func die(code<i8>)

//sleep ; implement by asm
func sleep(sec<u64>)

//sleep ; implement by asm
func usleep(sec<u64>)

//brk ; implement by asm
func brk(brk<u64>)

//execv ; implement by asm
func execve(filename<i8*>,argv<i8*>,envp<i8*>)