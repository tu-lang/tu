// Mixed subtree: static and dynamic definitions coexist unchecked.

mem Pt {
    i32 x
}

Pt::x2() i32 {
    return this.x * 2
}

func three() {
    return 3
}
