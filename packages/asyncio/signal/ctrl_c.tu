// ctrl_c — resolve on the first SIGINT, built on sync
// signal(SignalKind::interrupt()) plus an awaited recv.
// Tu: leaf future — register on first poll, then drive RecvFut directly.

use io
use runtime

// Leaf for public ctrl_c().
mem CtrlCFut: async {
    i32 stage
    RecvFut* recv_fut
}

CtrlCFut::poll(ctx) {
    if this.stage == 0 {
        serr<i32> = subscribe(kind_interrupt())
        if serr != io.Ok return runtime.PollReady, serr
        stream<SignalStream> = stream_last()
        if stream == null return runtime.PollReady, io.Other
        this.recv_fut = stream.recv()
        this.stage = 1
    }
    // Unpack multi-return; bare `return recv_fut.poll(ctx)` can drop the value.
    code<i32>, val = this.recv_fut.poll(ctx)
    return code, val
}

// Awaitable until first SIGINT after poll. Returns the concrete leaf
// (same pattern as SignalStream::recv → RecvFut); callers `.await` it.
fn ctrl_c() CtrlCFut {
    return new CtrlCFut {
        stage: 0,
        recv_fut: null
    }
}
