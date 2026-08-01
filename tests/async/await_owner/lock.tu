// Owner package for cross-pkg member-async .await tests.
// Consumer: tests/async/member_await_cross.tu (use await_owner as own).
use runtime

mem Lock {
    i32 n
}

// Untyped `m = lock_new()` must pick up Lock via return-type propagation.
fn lock_new() Lock {
    return new Lock { n: 0 }
}

// Async member leaf; consumer awaits across package boundary.
async Lock::lock() {
    return 1.(i8)
}

async Lock::pending_then_ready() {
    // One Pending then Ready so poll/state machine is exercised.
    if this.n == 0 {
        this.n = 1
        return runtime.PollPending
    }
    return 2.(i8)
}
