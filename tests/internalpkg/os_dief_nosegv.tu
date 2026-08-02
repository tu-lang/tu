// C3: os.dief must exit with a normal status, never SIGSEGV from intentional *null.

use fmt
use os
use std

fn test_dief_child_status(){
    fmt.println("test_dief_child_status")
    // Fork: child calls dief; parent waitpid and reject signalled death.
    pid<i64> = std.fork()
    if pid < 0 {
        os.die("fork failed")
    }
    if pid == 0 {
        os.dief("dief child %d", 7)
        // not reached
        os.exit(1)
    }
    st<u64> = 0
    w<i32> = std.waitpid(pid.(i32), &st, 0)
    if w < 0 {
        os.die("waitpid failed")
    }
    // Linux: if signalled, low 7 bits of status are the signal (SIGSEGV=11).
    sig<u64> = st & 0x7f.(u64)
    if sig == 11.(u64) {
        os.die("os.dief still died by SIGSEGV")
    }
    // Normal exit path from std.die(-1): WIFEXITED
    exited<u64> = (st >> 8.(u64)) & 0xff.(u64)
    if sig != 0.(u64) {
        os.dief("dief child signalled sig=%d", sig.(i32))
    }
    if exited == 0.(u64) {
        os.die("dief child exited 0 unexpectedly")
    }
    fmt.println("test_dief_child_status success")
}

fn main(){
    test_dief_child_status()
    fmt.println("os_dief_nosegv passed")
}
