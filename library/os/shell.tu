use std
use runtime

EXIT_CODE<i32> = 127

// Static helper for shell(); not a dyn facade.
fn system_argv(sh<u64*>, c<u64*>, cmd<u64*>){
    argv<i8*> = new 32 
    p<u64*> = argv
    *p = sh  p += 8
    *p = c   p += 8
    *p = cmd p += 8
    *p = 0
    return argv
}
 
export func shell(cmd)
{
    cv<runtime.Value> = cmd
    if cv == null || cv.type != runtime.String {
        std.die(EXIT_CODE)
    }
    cstr<i8*> = cv.data
    argv<u64*> = system_argv(*"sh",*"-c",cstr)
    if fork() == 0 {
        std.execve(*"/bin/sh",argv,runtime.ori_envp)
        std.die(EXIT_CODE)
    }
    _wait4()
}