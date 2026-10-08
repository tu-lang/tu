// expect: await: operand is not awaitable
// A statically typed native value cannot be awaited.
use runtime

async work(){
    x<i32> = 5
    y<i32> = x.await
    return y
}

fn main(){
    runtime.block(work())
}
