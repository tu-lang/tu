// A sync member returning a string cannot be awaited (call-arg position).
use runtime
use fmt

class W {
    func init(){}
    func word(){ return "x" }
}
func id(a){ return a }

async work(){
    w = new W()
    return id(w.word().await)
}

fn main(){
    fmt.println(runtime.block(work()))
}
