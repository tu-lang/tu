// Integration test for asyncio.signal (task 18.4): int_ctrl_c_self_kill.
//   - subscribe to SIGUSR1 and SIGINT
//   - raise SIGUSR1 to ourselves
//   - SIGUSR1 recv() resolves; the SIGINT stream must stay un-fired
//
// Requires the signal driver running on the runtime root (signalfd drain +
// EventInfo::fire after each IO turn). Linux-only; validated on Linux CI, not
// the Windows host.
//
// Mother: tokio::signal::unix::signal is sync; recv().await is async.
// Call sites use sig.subscribe / sig.kind_* — not sig.signal* (type-assert trap).

use fmt
use os
use io
use sys
use string
use runtime
use asyncio.runtime as rt
use asyncio.signal as sig

// task 18.4: SIGUSR1 self-kill wakes its stream while SIGINT stays quiet.
async sig_usr1_body() {
    ok_code<i32> = io.Ok
    bad<i32> = io.OtherParse

    ierr<i32> = sig.subscribe(sig.kind_interrupt())
    if ierr != ok_code return ierr
    int_stream<sig.SignalStream> = sig.stream_last()
    if int_stream == null return bad

    uerr<i32> = sig.subscribe(sig.kind_user_defined1())
    if uerr != ok_code return uerr
    usr_stream<sig.SignalStream> = sig.stream_last()
    if usr_stream == null return bad

    // Send SIGUSR1 to our own process; register() has already blocked it so it
    // queues into the signalfd instead of running the default action.
    // os._getpid is the raw syscall (typed i32 path); os.getpid() dynamic
    // int→i32 corrupts the pid (strace: kill(garbage)).
    // Local i32 for kill's 2nd arg (literal 2nd-arg corruption trap).
    pid_i<i32> = 0
    pid_i = os._getpid()
    sigusr1<i32> = 10
    kerr<i32> = sys.kill(pid_i, sigusr1)
    if kerr < 0 return bad

    rfut<sig.RecvFut> = usr_stream.recv()
    rerr<i32> = rfut.await
    if rerr != ok_code return rerr

    // We never raised SIGINT, so its stream must have nothing pending.
    if int_stream.try_recv() != 0 return bad

    return ok_code
}

// Drive one body via builder_block_on (same path as int_process_echo / macros).
fn run_body(name<i8*>, body) {
    b<rt.Builder> = rt.Builder::new_current_thread()
    // enable_io only: enable_all's TimeDriver + outer await Pending currently
    // SIGSEGV on the await return path; IO park is enough for signalfd.
    b = b.enable_io()
    body_f<runtime.Future> = body
    fut<u64> = 0
    fut = body_f
    rerr<i32>, result<i64> = rt.builder_block_on(b, fut, 0)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    ri<i32> = 0
    ri = result
    if ri != io.Ok os.dief("signal body failed: %d", ri)
    fmt.println(string.new(name))
}

fn int_ctrl_c_self_kill(){
    fmt.println("int_ctrl_c_self_kill test")
    run_body("  sig_usr1 passed", sig_usr1_body())
    fmt.println("int_ctrl_c_self_kill passed")
}

fn main(){
    int_ctrl_c_self_kill()
}
