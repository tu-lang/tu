// Static subpackage inside a manifest-free tree: mem/fn are legal here.

use runtime

// Pair of native ints.
mem Pair {
    i32 a, b
}

// Sums the pair fields.
fn sum_raw(p<Pair>) i32 {
    return p.a + p.b
}

// Dynamic facade: builds a Pair from dyn ints and returns the dyn sum.
export func make_sum(a, b) {
    ra<runtime.Value> = a
    rb<runtime.Value> = b
    p<Pair> = new Pair { a: ra.data, b: rb.data }
    return int(sum_raw(p))
}
