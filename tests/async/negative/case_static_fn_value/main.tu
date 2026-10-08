// expect: static value without awaitable type
// A static fn returning a native value is not awaitable.
use runtime

fn sadd(a<i32>, b<i32>) i32 { return a + b }

async work(){
    r<i32> = sadd(1, 2).await + 1
    return r
}

fn main(){
    runtime.block(work())
}
