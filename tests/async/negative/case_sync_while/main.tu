// .await inside a while condition of a sync function is rejected.
use fmt

class W {
    func init(){}
}
async W::seven(){ return 7 }

fn main(){
    w = new W()
    i = 0
    while i < w.seven().await {
        i += 1
    }
    fmt.println(i)
}
