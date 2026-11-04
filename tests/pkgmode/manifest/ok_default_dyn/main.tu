// expect: ok

class Box {
    v
    func init(x) {
        this.v = x
    }
    func get() {
        return this.v
    }
}

func main() {
    b = new Box(3)
    if b.get() != 3 {
        os.die("Box.get expected 3")
    }
    fmt.println("ok")
}
