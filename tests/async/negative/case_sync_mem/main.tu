// .await inside a sync mem method body is rejected.
use fmt

mem M {
    i32 n
}
async M::seven(){ return 7.(i8) }
M::sum() i32 {
    return this.n + this.seven().await
}

fn main(){
    m<M> = new M{n: 1}
    fmt.println(int(m.sum()))
}
