// expect: .await used outside async function
// A negated .await inside a sync function body is rejected.
use fmt

class W {
    func init(){}
}
async W::seven(){ return 7 }

fn main(){
    w = new W()
    x = -w.seven().await
    fmt.println(x)
}
