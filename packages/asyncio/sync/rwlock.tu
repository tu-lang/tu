// Async RwLock backed by BatchSemaphore(MAX_READERS). A reader claims one
// permit; the writer claims all MAX_READERS at once. Guards must release
// explicitly (TuLang has no Drop).

MAX_READERS<u32> = 0x10000     // 65536 concurrent readers cap

// Lock state over a u64 slot. value lifetime is the caller's job.
mem RwLock {
    BatchSemaphore* sem
    u64             slot
}

// Build a fresh lock with `value` bits (0 = uninitialised).
const RwLock::new(value<u64>) RwLock* {
    l<RwLock> = new RwLock
    l.sem  = BatchSemaphore::new(MAX_READERS)
    l.slot = value
    return &l
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

ReadGuard::release(){
    s<BatchSemaphore> = this.lock.sem
    s.release(1)
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

WriteGuard::release(){
    s<BatchSemaphore> = this.lock.sem
    s.release(MAX_READERS)
}

// Acquire a shared lock. Returns (0, ReadGuard) or (Closed, empty guard).
async RwLock::read(){
    err<i32> = this.sem.acquire(1).await
    if err != 0 return err, new ReadGuard { lock: null }
    return 0, ReadGuard::new(this)
}

// Acquire an exclusive lock. Returns (0, WriteGuard) or (Closed, empty).
async RwLock::write(){
    err<i32> = this.sem.acquire(MAX_READERS).await
    if err != 0 return err, new WriteGuard { lock: null }
    return 0, WriteGuard::new(this)
}

