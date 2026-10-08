// A sync member returning null cannot be awaited (condition position).
use runtime

class W {
    func init(){}
    func none(){ return null }
}

async work(){
    w = new W()
    if w.none().await == 1 {
        return 1
    }
    return 0
}

fn main(){
    runtime.block(work())
}
