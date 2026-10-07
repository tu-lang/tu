use std
use runtime

EXIT_CODE<i32> = 127
EINTR<i32> = -4

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

// Decodes a wait status word: exit code on normal exit, 128+signal when
// killed by a signal (shell convention), -1 for anything else.
fn shell_exit_code(status<i32>) i32 {
    sig<i32> = status & 127
    if sig == 0 {
        return (status >> 8) & 255
    }
    if sig == 127 {
        return -1
    }
    return 128 + sig
}

// Runs cmd via /bin/sh -c and waits for that child.
// Returns the shell's exit code (128+signal if killed), or -1 if the child
// could not be spawned or reaped.
export func shell(cmd)
{
    cv<runtime.Value> = cmd
    if cv == null || cv.type != runtime.String {
        std.die(EXIT_CODE)
    }
    cstr<i8*> = cv.data
    argv<u64*> = system_argv(*"sh",*"-c",cstr)
    pid<i64> = std.fork()
    if pid == 0 {
        std.execve(*"/bin/sh",argv,runtime.ori_envp)
        std.die(EXIT_CODE)
    }
    if pid < 0 {
        return -1
    }
    st<i32> = 0
    sp<i32*> = &st
    rc<i32> = EINTR
    while rc == EINTR {
        rc = std.waitpid(pid.(i32), sp.(u64), 0)
    }
    if rc < 0 {
        return -1
    }
    code<i32> = shell_exit_code(st)
    return int(code)
}
