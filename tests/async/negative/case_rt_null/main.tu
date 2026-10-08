// Awaiting a null dynamic value dies at run time.
use runtime

class H {
    f
    func init(){}
}

async work(){
    h = new H()
    return h.f.await
}

fn main(){
    runtime.block(work())
}
