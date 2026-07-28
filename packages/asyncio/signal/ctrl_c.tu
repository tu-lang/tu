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
    return this.recv_fut.poll(ctx)
}

// Awaitable until first SIGINT after poll.
fn ctrl_c() runtime.Future {
    f<CtrlCFut> = new CtrlCFut {
        stage: 0,
        recv_fut: null
    }
    fut<runtime.Future> = f
    return fut
}
