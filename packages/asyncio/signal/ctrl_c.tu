// ctrl_c — resolve on the first SIGINT, built on sync
// signal(SignalKind::interrupt()) plus an awaited recv.
// Tu: leaf future — register on first poll, then drive erased recv Future
// (no package async+await; that hits return-count parse errors).

use io
use runtime

// Leaf for public ctrl_c().
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

// Awaitable until first SIGINT after poll.
fn ctrl_c() runtime.Future {
    return new CtrlCFut {
        stage: 0,
        recv_bits: 0
    }
}
