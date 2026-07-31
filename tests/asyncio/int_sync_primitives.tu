// Integration smoke for asyncio.sync (task 12.31): Notify / Mutex / oneshot /
// Semaphore / RwLock / Barrier / OnceCell under multi_thread + enable_all.

use fmt
use os
use io
use runtime
use asyncio.runtime as rt
use asyncio.task
use asyncio.sync as sync
use asyncio.time as atime

g_notify_bits<u64> = 0
g_tx_bits<u64> = 0
g_rx_bits<u64> = 0
g_barrier_bits<u64> = 0

async notify_waiter_body() {
    nf<sync.Notified> = sync.notified_from_bits(g_notify_bits)
    code<i32> = nf.await
    if code != 0 return code.(i64)
    return io.Ok.(i64)
}

fn notify_waiter_fut() runtime.Future {
    return notify_waiter_body()
}

async notify_smoke_body() {
    n<sync.Notify> = sync.Notify::new()
    g_notify_bits = n.(u64)
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    jh<task.JoinHandle> = h.spawn(notify_waiter_fut())
    e1<i32> = atime.sleep(atime.from_millis(20)).await
    if e1 != io.Ok return e1.(i64)
    n.notify_one()
    v<i64> = jh.await
    return v
}

async oneshot_sender_body() {
    e1<i32> = atime.sleep(atime.from_millis(15)).await
    if e1 != io.Ok return e1.(i64)
    serr<i32> = sync.oneshot_send_bits(g_tx_bits, 42)
    if serr != 0 return serr.(i64)
    return io.Ok.(i64)
}

fn oneshot_sender_fut() runtime.Future {
    return oneshot_sender_body()
}

async oneshot_smoke_body() {
    txb<u64>, rxb<u64> = sync.oneshot_channel_bits()
    g_tx_bits = txb
    g_rx_bits = rxb
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    jh<task.JoinHandle> = h.spawn(oneshot_sender_fut())
    rf<sync.RecvFut> = sync.oneshot_recv_fut_bits(g_rx_bits)
    val<i64> = rf.await
    if val.(i32) == 0x03020002 return io.OtherParse.(i64)
    sv<i64> = jh.await
    if sv.(i32) != io.Ok return sv
    if val.(i32) != 42 return io.OtherParse.(i64)
    return io.Ok.(i64)
}

async mutex_smoke_body() {
    m<sync.Mutex> = sync.Mutex::new(0)
    mb<u64> = m.(u64)
    f1<sync.AcquireFut> = sync.mutex_acquire_fut_bits(mb)
    lerr<i32> = f1.await
    if lerr != 0 return lerr.(i64)
    g1<u64> = sync.mutex_guard_bits(mb)
    sync.mutex_guard_set_bits(g1, 7)
    sync.mutex_guard_give_back_bits(g1)
    f2<sync.AcquireFut> = sync.mutex_acquire_fut_bits(mb)
    lerr2<i32> = f2.await
    if lerr2 != 0 return lerr2.(i64)
    g2<u64> = sync.mutex_guard_bits(mb)
    got<u64> = sync.mutex_guard_get_bits(g2)
    sync.mutex_guard_give_back_bits(g2)
    if got.(i32) != 7 return io.OtherParse.(i64)
    return io.Ok.(i64)
}

// Mutex::acquire leaf + guard bits, then a follow-up MT runtime (poison check).
async mutex_lock_bits_body() {
    m<sync.Mutex> = sync.Mutex::new(0)
    mb<u64> = m.(u64)
    f<sync.AcquireFut> = sync.mutex_acquire_fut_bits(mb)
    lerr<i32> = f.await
    if lerr != 0 return lerr.(i64)
    gb<u64> = sync.mutex_guard_bits(mb)
    sync.mutex_guard_set_bits(gb, 9)
    got<u64> = sync.mutex_guard_get_bits(gb)
    sync.mutex_guard_give_back_bits(gb)
    if got.(i32) != 9 return io.OtherParse.(i64)
    return io.Ok.(i64)
}

async after_mutex_sleep_body() {
    e1<i32> = atime.sleep(atime.from_millis(5)).await
    if e1 != io.Ok return e1.(i64)
    return io.Ok.(i64)
}

async sem_smoke_body() {
    s<sync.Semaphore> = sync.Semaphore::new(1)
    sb<u64> = s.(u64)
    aerr<i32>, p1<u64> = sync.semaphore_try_acquire_bits(sb, 1)
    if aerr != 0 return aerr.(i64)
    sync.permit_give_back_bits(p1)
    aerr2<i32>, p2<u64> = sync.semaphore_try_acquire_bits(sb, 1)
    if aerr2 != 0 return aerr2.(i64)
    // Hold p2 and expect next try to fail.
    aerr3<i32>, p3<u64> = sync.semaphore_try_acquire_bits(sb, 1)
    if aerr3 == 0 {
        sync.permit_give_back_bits(p3)
        sync.permit_give_back_bits(p2)
        return io.OtherParse.(i64)
    }
    sync.permit_give_back_bits(p2)
    return io.Ok.(i64)
}

async rwlock_smoke_body() {
    l<sync.RwLock> = sync.RwLock::new(0)
    lb<u64> = l.(u64)
    wf<sync.AcquireFut> = sync.rwlock_write_fut_bits(lb)
    werr<i32> = wf.await
    if werr != 0 return werr.(i64)
    wg<u64> = sync.rwlock_write_guard_bits(lb)
    sync.write_guard_set_bits(wg, 9)
    sync.write_guard_give_back_bits(wg)
    rf<sync.AcquireFut> = sync.rwlock_read_fut_bits(lb)
    rerr<i32> = rf.await
    if rerr != 0 return rerr.(i64)
    rg<u64> = sync.rwlock_read_guard_bits(lb)
    got<u64> = sync.read_guard_get_bits(rg)
    sync.read_guard_give_back_bits(rg)
    if got.(i32) != 9 return io.OtherParse.(i64)
    return io.Ok.(i64)
}

async once_cell_smoke_body() {
    c<sync.OnceCell> = sync.OnceCell::new()
    serr<i32> = c.set(11)
    if serr != 0 return serr.(i64)
    gerr<i32>, got<u64> = c.get()
    if gerr != 0 return gerr.(i64)
    if got.(i32) != 11 return io.OtherParse.(i64)
    return io.Ok.(i64)
}

async barrier_peer_body() {
    f<sync.BarrierWaitFut> = sync.barrier_wait_fut_bits(g_barrier_bits)
    leader<i64> = f.await
    return leader
}

fn barrier_peer_fut() runtime.Future {
    return barrier_peer_body()
}

// Two waiters via leaf BarrierWaitFut; exactly one leader; then next MT must stay clean.
async barrier_smoke_body() {
    b<sync.Barrier> = sync.Barrier::new(2)
    g_barrier_bits = b.(u64)
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    jh<task.JoinHandle> = h.spawn(barrier_peer_fut())
    f0<sync.BarrierWaitFut> = sync.barrier_wait_fut_bits(g_barrier_bits)
    lead0<i64> = f0.await
    lead1<i64> = jh.await
    sum<i32> = lead0.(i32) + lead1.(i32)
    if sum != 1 return io.OtherParse.(i64)
    return io.Ok.(i64)
}

async after_barrier_sleep_body() {
    e1<i32> = atime.sleep(atime.from_millis(5)).await
    if e1 != io.Ok return e1.(i64)
    return io.Ok.(i64)
}

// Avoid os.dief("%s", dyn) here — mixes with MT Notify futures and SEGV'd.
fn check_ok(name, rerr<i32>, result<i64>) {
    if rerr != 0 {
        fmt.println(name)
        fmt.println("block_on failed")
        fmt.println(int(rerr))
        os.exit(1)
    }
    ri<i32> = result
    if ri != io.Ok {
        fmt.println(name)
        fmt.println("body failed")
        fmt.println(int(ri))
        os.exit(1)
    }
    fmt.println(name)
}

fn int_sync_primitives_smoke() {
    fmt.println("int_sync_primitives_smoke test")

    b1<rt.Builder> = rt.Builder::new_multi_thread()
    b1 = b1.worker_threads(4)
    b1 = b1.enable_all()
    e1<i32>, v1<i64> = rt.builder_block_on(b1, notify_smoke_body(), 0)
    check_ok("  notify passed", e1, v1)

    b2<rt.Builder> = rt.Builder::new_multi_thread()
    b2 = b2.worker_threads(4)
    b2 = b2.enable_all()
    e2<i32>, v2<i64> = rt.builder_block_on(b2, oneshot_smoke_body(), 0)
    check_ok("  oneshot passed", e2, v2)

    b3<rt.Builder> = rt.Builder::new_multi_thread()
    b3 = b3.worker_threads(4)
    b3 = b3.enable_all()
    e3<i32>, v3<i64> = rt.builder_block_on(b3, mutex_smoke_body(), 0)
    check_ok("  mutex passed", e3, v3)

    b3b<rt.Builder> = rt.Builder::new_multi_thread()
    b3b = b3b.worker_threads(4)
    b3b = b3b.enable_all()
    e3b<i32>, v3b<i64> = rt.builder_block_on(b3b, mutex_lock_bits_body(), 0)
    check_ok("  mutex_lock_bits passed", e3b, v3b)

    b3c<rt.Builder> = rt.Builder::new_multi_thread()
    b3c = b3c.worker_threads(4)
    b3c = b3c.enable_all()
    e3c<i32>, v3c<i64> = rt.builder_block_on(b3c, after_mutex_sleep_body(), 0)
    check_ok("  after_mutex_sleep passed", e3c, v3c)

    b4<rt.Builder> = rt.Builder::new_multi_thread()
    b4 = b4.worker_threads(4)
    b4 = b4.enable_all()
    e4<i32>, v4<i64> = rt.builder_block_on(b4, sem_smoke_body(), 0)
    check_ok("  semaphore passed", e4, v4)

    b5<rt.Builder> = rt.Builder::new_multi_thread()
    b5 = b5.worker_threads(4)
    b5 = b5.enable_all()
    e5<i32>, v5<i64> = rt.builder_block_on(b5, rwlock_smoke_body(), 0)
    check_ok("  rwlock passed", e5, v5)

    b7<rt.Builder> = rt.Builder::new_multi_thread()
    b7 = b7.worker_threads(4)
    b7 = b7.enable_all()
    e7<i32>, v7<i64> = rt.builder_block_on(b7, once_cell_smoke_body(), 0)
    check_ok("  once_cell passed", e7, v7)

    b8<rt.Builder> = rt.Builder::new_multi_thread()
    b8 = b8.worker_threads(4)
    b8 = b8.enable_all()
    e8<i32>, v8<i64> = rt.builder_block_on(b8, barrier_smoke_body(), 0)
    check_ok("  barrier passed", e8, v8)

    b8b<rt.Builder> = rt.Builder::new_multi_thread()
    b8b = b8b.worker_threads(4)
    b8b = b8b.enable_all()
    e8b<i32>, v8b<i64> = rt.builder_block_on(b8b, after_barrier_sleep_body(), 0)
    check_ok("  after_barrier_sleep passed", e8b, v8b)

    fmt.println("int_sync_primitives_smoke passed")
}

fn main() {
    int_sync_primitives_smoke()
}
