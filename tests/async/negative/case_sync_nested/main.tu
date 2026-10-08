// A nested .await inside a sync function body must be rejected at compile time.
use fmt

class W {
    func init(){}
}
async W::seven(){ return 7 }
func plus(a, b){ return a + b }

fn main(){
    w = new W()
    fmt.println(plus(w.seven().await, 1))
}
