// Static subtree (prefix "a"): export facade over static fn.

fn one() i32 {
    return 1
}

export func oneDyn() {
    return int(one())
}
