// A sync member returning a plain int cannot be awaited.
use runtime

class W {
    func init(){}
    func num(){ return 5 }
}

async work(){
    w = new W()
    return w.num().await + 1
}

fn main(){
    runtime.block(work())
}
