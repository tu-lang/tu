// Cross-pkg member-async .await must resolve leaf in the owner package
// (genawait2 pkg annot aligned with leafawait). Second block_on must stay healthy.
use fmt
use os
use runtime
use await_owner as own

mem LocalLock {
    i32 n
}
async LocalLock::lock() {
    return 3.(i8)
}

async cross_lock_once() {
    m<own.Lock> = new own.Lock { n: 0 }
    return m.lock().await
}

async cross_pending_once() {
    m<own.Lock> = new own.Lock { n: 0 }
    return m.pending_then_ready().await
}

async local_lock_once() {
    m<LocalLock> = new LocalLock { n: 0 }
    return m.lock().await
}

fn test_cross_member_await() {
    fmt.println("test_cross_member_await")
    r1<i64> = runtime.block(cross_lock_once())
    if r1 != 1 {
        os.die("cross lock().await != 1")
    }
    // Second block_on: poison check after cross-pkg member-async.
    r2<i64> = runtime.block(local_lock_once())
    if r2 != 3 {
        os.die("follow-up local lock poisoned")
    }
    fmt.println("test_cross_member_await success")
}

fn test_cross_pending_await() {
    fmt.println("test_cross_pending_await")
    r<i64> = runtime.block(cross_pending_once())
    if r != 2 {
        os.die("cross pending_then_ready().await != 2")
    }
    r2<i64> = runtime.block(local_lock_once())
    if r2 != 3 {
        os.die("follow-up after pending poisoned")
    }
    fmt.println("test_cross_pending_await success")
}

fn main() {
    test_cross_member_await()
    test_cross_pending_await()
}
