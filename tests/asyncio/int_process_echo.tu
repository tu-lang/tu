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
use std
use runtime
use asyncio.runtime as rt
use asyncio.process as proc

// Byte-compare via io.buf_* bridges (same helper as int_fs_roundtrip).
fn buf_equals(buf<io.Buf>, expect<string.String>) i32 {
    ep<i8*> = string.cstr(expect)
    elen_i<i32> = std.strlen(ep)
    elen<u64> = elen_i.(u64)
    if io.buf_len(buf) != elen return 0
    a<u8*> = io.buf_ptr(buf)
    b<u8*> = ep
    i<u64> = 0
    while i < io.buf_len(buf) {
        if a[i] != b[i] return 0
        i += 1
    }
    return 1
}

// task 17.9: /bin/echo hi writes "hi\n" to stdout and exits 0.
// Mother: tokio::process::Command::output (tests/docs examples with echo).
async proc_echo_body() {
    ok_code<i32> = io.Ok
    bad<i32> = io.OtherParse
    c<proc.Command> = proc.Command::new(string.S(*"/bin/echo"))
    c = c.arg(string.S(*"hi"))

    oerr<i32>, out<proc.Output> = c.output().await
    if oerr != ok_code return oerr
    // Avoid ExitStatus::success() bool (type-info trap); mother success = code 0.
    scode<i32> = out.status.code()
    ssig<i32> = out.status.signal()
    if scode != 0 return bad
    if ssig != 0 return bad
    if buf_equals(out.stdout, string.S(*"hi\n")) == 0 return bad

    return ok_code
}

// task 17.10: spawn a long sleep, SIGKILL it, and confirm wait reports the
// terminating signal (SIGKILL = 9). Mother: Child::start_kill + wait.
async proc_kill_body() {
    ok_code<i32> = io.Ok
    bad<i32> = io.OtherParse
    c<proc.Command> = proc.Command::new(string.S(*"/bin/sleep"))
    c = c.arg(string.S(*"100"))

    serr<i32>, child<proc.Child> = c.spawn()
    if serr != ok_code return serr

    kerr<i32> = child.start_kill()
    if kerr != ok_code return kerr

    werr<i32>, es<proc.ExitStatus> = child.wait().await
    if werr != ok_code return werr
    if es.signal() != 9 return bad

    return ok_code
}

// Drive one body via builder_block_on (same path as int_fs_roundtrip / macros).
fn run_body(name<i8*>, body) {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    body_f<runtime.Future> = body
    fut<u64> = 0
    fut = body_f
    rerr<i32>, result<i64> = rt.builder_block_on(b, fut, 0)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    ri<i32> = 0
    ri = result
    if ri != io.Ok os.dief("process body failed: %d", ri)
    fmt.println(string.new(name))
}

fn int_process_echo(){
    fmt.println("int_process_echo test")
    run_body("  proc_echo passed", proc_echo_body())
    run_body("  proc_kill passed", proc_kill_body())
    fmt.println("int_process_echo passed")
}

fn main(){
    int_process_echo()
}
