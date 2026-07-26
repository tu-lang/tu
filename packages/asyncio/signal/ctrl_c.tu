// tokio::signal::ctrl_c — resolve on the first SIGINT.
//
// Mother: async fn ctrl_c() { os_impl::ctrl_c()?.recv().await; Ok(()) }
// where unix::ctrl_c() is sync signal(SignalKind::interrupt()).
// Tu: leaf future — register on first poll, then drive erased recv Future
// (no package async+await; that hits return-count parse errors).

use io
use runtime

// Leaf for public ctrl_c() (mother async ctrl_c).
mem CtrlCFut: async {
    i32 stage
    u64 recv_bits
}

CtrlCFut::poll(ctx) {
    if this.stage == 0 {
        serr<i32> = subscribe(kind_interrupt())
        if serr != io.Ok return runtime.PollReady, serr
        stream<SignalStream> = stream_last()
        if stream == null return runtime.PollReady, io.Other
        rfut<runtime.Future> = stream.recv()
        this.recv_bits = rfut.(u64)
        this.stage = 1
    }
    rf<runtime.Future> = this.recv_bits
    return rf.poll()
}

// Mother: signal::ctrl_c — awaitable until first SIGINT after poll.
fn ctrl_c() runtime.Future {
    return new CtrlCFut {
        stage: 0,
        recv_bits: 0
    }
}
