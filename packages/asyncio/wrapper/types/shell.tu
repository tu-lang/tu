// Listener / Stream dynamic shells holding engine object pointers in `raw`.

class Listener {
    raw = 0
    func init(bits) {
        this.raw = bits
    }
}

class Stream {
    raw = 0
    func init(bits) {
        this.raw = bits
    }
}

func listenerFrom(engine_obj) {
    lis = new Listener(0)
    lis.raw = engine_obj
    return lis
}

func streamFrom(engine_obj) {
    st = new Stream(0)
    st.raw = engine_obj
    return st
}

func dial() {
    return new Stream(0)
}
