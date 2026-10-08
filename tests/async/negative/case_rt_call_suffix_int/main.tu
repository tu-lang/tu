// expect: call not func object
// A chained call suffix on a non-closure value dies before the await.
use runtime

async work(){
    arr = [7]
    return arr[0]().await
}

fn main(){
    runtime.block(work())
}
