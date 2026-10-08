// expect: func not async
// A sync mem method returning a native value is not awaitable.
use runtime

mem M {
    i32 n
}
M::get() i32 { return this.n }

async work(){
    m<M> = new M{n: 1}
    if m.get().await == 1 {
        return 1.(i8)
    }
    return 0.(i8)
}

fn main(){
    runtime.block(work())
}
