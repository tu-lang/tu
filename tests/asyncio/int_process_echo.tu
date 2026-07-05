// Integration tests for asyncio.process (tasks 17.9 / 17.10):
//   - echo: Command::new("/bin/echo").arg("hi").output() -> stdout == "hi\n"
//   - kill: spawn "/bin/sleep 100", start_kill, wait -> SIGKILL ExitStatus
//
// fork/exec/waitpid are Linux-only and run inline (V1); validated on Linux CI,
// not the Windows host.

use fmt
use os
use io
use string
use asyncio.runtime as rt
use asyncio.process as proc

// Byte-compare a captured buffer against expected string bytes.
fn buf_equals(buf<io.Buf>, expect<string.String>) bool {
    if buf.len() != expect.len().(u64) return false
    a<u8*> = buf.ptr()
    b<u8*> = expect.str()
    i<u64> = 0
    while i < buf.len() {
        if a[i] != b[i] return false
        i += 1
    }
    return true
}

// task 17.9: /bin/echo hi writes "hi\n" to stdout and exits 0.
async proc_echo_body() i32 {
    c<proc.Command> = proc.Command::new(string.S(*"/bin/echo"))
    c = c.arg(string.S(*"hi"))

    oerr<i32>, out<proc.Output> = c.output().await
    if oerr != io.Ok return oerr
    if out.status.success() == false return io.OtherParse
    if buf_equals(out.stdout, string.S(*"hi\n")) == false return io.OtherParse

    return io.Ok
}

// task 17.10: spawn a long sleep, SIGKILL it, and confirm wait reports the
// terminating signal (SIGKILL = 9).
async proc_kill_body() i32 {
    c<proc.Command> = proc.Command::new(string.S(*"/bin/sleep"))
    c = c.arg(string.S(*"100"))

    serr<i32>, child<proc.Child> = c.spawn()
    if serr != io.Ok return serr

    kerr<i32> = child.start_kill()
    if kerr != io.Ok return kerr

    werr<i32>, es<proc.ExitStatus> = child.wait().await
    if werr != io.Ok return werr
    if es.signal() != 9 return io.OtherParse

    return io.Ok
}

// Drive future `body` to completion on `r`, aborting on any failure.
fn run_body(r<rt.Runtime>, name<i8*>, body) {
    rerr<i32>, result<i64> = r.block_on(body)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    if result.(i32) != io.Ok os.dief("process body failed: %d", result.(i32))
    fmt.println(name)
}

fn int_process_echo(){
    fmt.println("int_process_echo test")

    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    berr<i32>, r<rt.Runtime> = b.build()
    if berr != 0 os.dief("runtime build failed: %d", berr)

    run_body(r, "  proc_echo passed", proc_echo_body())
    run_body(r, "  proc_kill passed", proc_kill_body())

    r.shutdown_background()
    fmt.println("int_process_echo passed")
}

fn main(){
    int_process_echo()
}
