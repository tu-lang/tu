// Cross-pkg member-async .await must resolve leaf in the owner package
// (genawait2 pkg annot aligned with leafawait). Second block_on must stay healthy.
// Also: untyped assign from typed factory + materialize leaf then .await.
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

// Untyped receiver: m = own.lock_new() must propagate Lock so m.lock().await is static.
async cross_untyped_recv_await() {
    m = own.lock_new()
    return m.lock().await
}

// Materialize member-async leaf then await the local (fut = m.lock(); fut.await).
async cross_materialize_leaf_await() {
    m = own.lock_new()
    fut = m.lock()
    return fut.await
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

fn test_cross_untyped_recv() {
    fmt.println("test_cross_untyped_recv")
    r<i64> = runtime.block(cross_untyped_recv_await())
    if r != 1 {
        os.die("untyped recv lock().await != 1")
    }
    r2<i64> = runtime.block(local_lock_once())
    if r2 != 3 {
        os.die("follow-up after untyped recv poisoned")
    }
    fmt.println("test_cross_untyped_recv success")
}

fn test_cross_materialize_leaf() {
    fmt.println("test_cross_materialize_leaf")
    r<i64> = runtime.block(cross_materialize_leaf_await())
    if r != 1 {
        os.die("materialize leaf await != 1")
    }
    r2<i64> = runtime.block(local_lock_once())
    if r2 != 3 {
        os.die("follow-up after materialize poisoned")
    }
    fmt.println("test_cross_materialize_leaf success")
}

fn main() {
    test_cross_member_await()
    test_cross_pending_await()
    test_cross_untyped_recv()
    test_cross_materialize_leaf()
}
