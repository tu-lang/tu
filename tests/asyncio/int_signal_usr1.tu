// Integration test for asyncio.signal (task 18.4): int_ctrl_c_self_kill.
//   - subscribe to SIGUSR1 and SIGINT
//   - raise SIGUSR1 to ourselves
//   - SIGUSR1 recv() resolves; the SIGINT stream must stay un-fired
//   - ctrl_c().await resolves on SIGINT (concrete CtrlCFut, no Future erase)
//
// Requires the signal driver running on the runtime root (signalfd drain +
// EventInfo::fire after each IO turn). Linux-only; validated on Linux CI, not
// the Windows host.
//
// Call sites use sig.subscribe / sig.kind_* — not sig.signal* (type-assert trap).

use fmt
use os
use io
use sys
use string
use asyncio.runtime as rt
use asyncio.signal as sig
use asyncio.time as atime
use asyncio.task as task

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

    rerr<i32> = usr_stream.recv().await
    if rerr != ok_code return rerr

    // We never raised SIGINT, so its stream must have nothing pending.
    if int_stream.try_recv() != 0 return bad

    return ok_code
}

// Raise SIGINT after a short Sleep so ctrl_c is already parked.
async kill_sigint_after_sleep() {
    e1<i32> = atime.sleep(atime.from_millis(30)).await
    if e1 != io.Ok return e1
    pid_i<i32> = 0
    pid_i = os._getpid()
    sigint<i32> = 2
    kerr<i32> = sys.kill(pid_i, sigint)
    if kerr < 0 return io.OtherParse
    return io.Ok
}

fn kill_sigint_fut() runtime.Future {
    return kill_sigint_after_sleep()
}

// task 18.4 follow-up: public ctrl_c() leaf awaits SIGINT.
async ctrl_c_body() {
    ok_code<i32> = io.Ok
    bad<i32> = io.OtherParse

    err_h<i32>, h<rt.Handle> = rt.Handle::current()
    if err_h != 0 return bad

    jh<task.JoinHandle> = h.spawn(kill_sigint_fut())
    cerr<i32> = sig.ctrl_c().await
    if cerr != ok_code return cerr

    // Join the killer so shutdown does not race the Sleep.
    jv<i64> = jh.await
    if jv.(i32) != ok_code return bad
    return ok_code
}

// Drive one body via builder_block_on (same path as int_process_echo / macros).
fn run_body(name<i8*>, body) {
    b<rt.Builder> = rt.Builder::new_current_thread()
    // IO + time + signal: signalfd parks through the aggregate Driver.
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, body, 0)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    ri<i32> = 0
    ri = result
    if ri != io.Ok os.dief("signal body failed: %d", ri)
    fmt.println(string.new(name))
}

// Same bodies under multi_thread + enable_all (workers + signalfd + time).
fn run_body_mt(name<i8*>, body) {
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, body, 0)
    if rerr != 0 os.dief("mt block_on failed: %d", rerr)
    ri<i32> = 0
    ri = result
    if ri != io.Ok os.dief("mt signal body failed: %d", ri)
    fmt.println(string.new(name))
}

fn int_ctrl_c_self_kill(){
    fmt.println("int_ctrl_c_self_kill test")
    run_body("  sig_usr1 passed", sig_usr1_body())
    run_body("  ctrl_c passed", ctrl_c_body())
    fmt.println("int_ctrl_c_self_kill passed")
}

fn int_ctrl_c_self_kill_mt(){
    fmt.println("int_ctrl_c_self_kill_mt test")
    run_body_mt("  mt sig_usr1 passed", sig_usr1_body())
    run_body_mt("  mt ctrl_c passed", ctrl_c_body())
    // Second MT runtime after signal work must stay clean.
    run_body_mt("  mt sig_usr1 again passed", sig_usr1_body())
    fmt.println("int_ctrl_c_self_kill_mt passed")
}

fn main(){
    int_ctrl_c_self_kill()
    int_ctrl_c_self_kill_mt()
}
