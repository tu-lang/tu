// Static fixture package: static fn + export facade (RFC-110 scheme A).

fn add(a<i32>, b<i32>) i32 {
    return a + b
}

export func addBridge() {
    x<i32> = 40
    y<i32> = 2
    return int(add(x, y))
}
