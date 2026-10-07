use runtime

// .await inside unsafe { } must be rejected at parse.
mem ReadyFut: async {
    i64 _pad
}
ReadyFut::poll(ctx) {
    return runtime.PollReady, 1.(i64)
}

fn main() {
    f<ReadyFut> = new ReadyFut{}
    unsafe {
        v = f.await
    }
}
