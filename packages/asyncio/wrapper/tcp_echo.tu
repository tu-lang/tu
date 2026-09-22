// TCP echo helpers for wrapper tests.

use io

export func cmp_dyn_eq(got, want) {
    if got == want {
        return io.Ok
    }
    return io.OtherParse
}
