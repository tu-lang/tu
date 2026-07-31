// Async RwLock backed by BatchSemaphore(MAX_READERS). A reader claims one
// permit; the writer claims all MAX_READERS at once. Guards must give_back
// explicitly (TuLang has no Drop).

MAX_READERS<u32> = 0x10000     // 65536 concurrent readers cap

// Lock state over a u64 slot. value lifetime is the caller's job.
mem RwLock {
    BatchSemaphore* sem
    u64             slot
}

// Build a fresh lock with `value` bits (0 = uninitialised).
const RwLock::new(value<u64>) RwLock {
    l<RwLock> = new RwLock
    l.sem  = BatchSemaphore::new(MAX_READERS)
    l.slot = value
    return l
}

// Read guard; releases one permit.
mem ReadGuard {
    RwLock* lock
}

// Build a read guard.
const ReadGuard::new(lock<RwLock>) ReadGuard {
    return new ReadGuard { lock: lock }
}

ReadGuard::get() u64 {
    return this.lock.slot
}

ReadGuard::give_back(){
    batch_sem_release(this.lock.sem, 1)
}

// Write guard; releases MAX_READERS permits.
mem WriteGuard {
    RwLock* lock
}

const WriteGuard::new(lock<RwLock>) WriteGuard {
    return new WriteGuard { lock: lock }
}

WriteGuard::get() u64 {
    return this.lock.slot
}

WriteGuard::set(value<u64>){
    this.lock.slot = value
}

WriteGuard::give_back(){
    batch_sem_release(this.lock.sem, MAX_READERS)
}

// Acquire a shared lock. Returns (0, ReadGuard) or (Closed, empty guard).
async RwLock::read(){
    fut<AcquireFut> = new AcquireFut
    fut.init(this.sem, 1)
    err<i32> = fut.await
    if err != 0 return err, new ReadGuard { lock: null }
    return 0, ReadGuard::new(this)
}

// Acquire an exclusive lock. Returns (0, WriteGuard) or (Closed, empty).
async RwLock::write(){
    fut<AcquireFut> = new AcquireFut
    fut.init(this.sem, MAX_READERS)
    err<i32> = fut.await
    if err != 0 return err, new WriteGuard { lock: null }
    return 0, WriteGuard::new(this)
}

fn rwlock_write_fut_bits(lock_bits<u64>) AcquireFut {
    l<RwLock> = lock_bits.(RwLock)
    fut<AcquireFut> = new AcquireFut{}
    fut.init(l.sem, MAX_READERS)
    return fut
}

fn rwlock_read_fut_bits(lock_bits<u64>) AcquireFut {
    l<RwLock> = lock_bits.(RwLock)
    fut<AcquireFut> = new AcquireFut{}
    fut.init(l.sem, 1)
    return fut
}

fn rwlock_write_guard_bits(lock_bits<u64>) u64 {
    l<RwLock> = lock_bits.(RwLock)
    return WriteGuard::new(l).(u64)
}

fn rwlock_read_guard_bits(lock_bits<u64>) u64 {
    l<RwLock> = lock_bits.(RwLock)
    return ReadGuard::new(l).(u64)
}

fn write_guard_set_bits(g_bits<u64>, v<u64>) {
    g<WriteGuard> = g_bits.(WriteGuard)
    g.set(v)
}

fn write_guard_give_back_bits(g_bits<u64>) {
    g<WriteGuard> = g_bits.(WriteGuard)
    g.give_back()
}

fn read_guard_get_bits(g_bits<u64>) u64 {
    g<ReadGuard> = g_bits.(ReadGuard)
    return g.get()
}

fn read_guard_give_back_bits(g_bits<u64>) {
    g<ReadGuard> = g_bits.(ReadGuard)
    g.give_back()
}
