// Integration test for asyncio.signal (task 18.4): int_ctrl_c_self_kill.
//   - subscribe to SIGUSR1 and SIGINT
//   - raise SIGUSR1 to ourselves
//   - SIGUSR1 recv() resolves; the SIGINT stream must stay un-fired
//
// Requires the signal driver running on the runtime root (signalfd drain +
// EventInfo::fire after each IO turn). Linux-only; validated on Linux CI, not
// the Windows host.

use fmt
use os
use io
use asyncio.runtime as rt
use asyncio.signal as sig

// task 18.4: SIGUSR1 self-kill wakes its stream while SIGINT stays quiet.
async sig_usr1_body() i32 {
    ierr<i32>, int_stream<sig.SignalStream> = sig.signal(sig.SignalKind_interrupt()).await
    if ierr != io.Ok return ierr

    uerr<i32>, usr_stream<sig.SignalStream> = sig.signal(sig.SignalKind_user_defined1()).await
    if uerr != io.Ok return uerr

    // Send SIGUSR1 to our own process; register() has already blocked it so it
    // queues into the signalfd instead of running the default action.
    pid<i64> = sys_getpid()
    sys_kill(pid.(i32), os.SIGUSR1)

    rerr<i32> = usr_stream.recv().await
    if rerr != io.Ok return rerr

    // We never raised SIGINT, so its stream must have nothing pending.
    if int_stream.try_recv() return io.OtherParse

    return io.Ok
}

// Drive future `body` to completion on `r`, aborting on any failure.
fn run_body(r<rt.Runtime>, name<i8*>, body) {
    rerr<i32>, result<i64> = r.block_on(body)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    if result.(i32) != io.Ok os.dief("signal body failed: %d", result.(i32))
    fmt.println(name)
}

fn int_ctrl_c_self_kill(){
    fmt.println("int_ctrl_c_self_kill test")

    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    berr<i32>, r<rt.Runtime> = b.build()
    if berr != 0 os.dief("runtime build failed: %d", berr)

    run_body(r, "  sig_usr1 passed", sig_usr1_body())

    r.shutdown_background()
    fmt.println("int_ctrl_c_self_kill passed")
}

fn main(){
    int_ctrl_c_self_kill()
}
