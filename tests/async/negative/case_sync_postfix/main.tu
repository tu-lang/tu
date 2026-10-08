// expect: .await used outside async function
// A postfix-after-.await chain inside a sync function body must be rejected.
use fmt

class W {
    base = 3
    func init(){}
}
async W::self(){ return this }

fn main(){
    w = new W()
    fmt.println(w.self().await.base)
}
