// Awaiting a dynamic value that is not a future dies at run time.
use runtime

async work(){
    x = 5
    return x.await + 1
}

fn main(){
    runtime.block(work())
}
