// expect: await on non-future value
// A dynamic package func returning a plain value cannot be awaited.
use runtime

func five(){ return 5 }

async work(){
    r = 0
    while r < five().await {
        r += 1
    }
    return r
}

fn main(){
    runtime.block(work())
}
