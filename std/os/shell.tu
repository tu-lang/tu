use std
use runtime

EXIT_CODE<i32> = 127

func system_argv(sh<u64*>,c<u64*>,cmd<u64*>){
    argv<i8*> = new 32 
    p<u64*> = argv
    *p = sh  p += 8
    *p = c   p += 8
    *p = cmd p += 8
    *p = 0
    return argv
}
 
func shell(cmd)
{
    argv<u64*> = system_argv(*"sh",*"-c",*cmd)
    if fork() == 0 {
        std.execve(*"/bin/sh",argv,runtime.ori_envp)
        std.die(EXIT_CODE)
    }
    _wait4()
}