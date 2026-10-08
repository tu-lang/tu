// expect: func not async
// A sync mem method reached through a receiver type assertion is not awaitable.
use runtime

mem XM {
    i32 base
}
XM::num() i32 { return this.base }

async work(m){
    return int(m.(XM).num().await)
}

fn main(){
    x<XM> = new XM{base: 1}
    runtime.block(work(x))
}
