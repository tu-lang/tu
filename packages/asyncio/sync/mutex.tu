// Async Mutex backed by BatchSemaphore(1). The guard re-permits via
// release(); callers must invoke MutexGuard::release explicitly because
// TuLang has no Drop.

// Async mutex over a u64 slot. Owners cast the slot via slot.(SomeMem).
mem Mutex {
    BatchSemaphore* sem
    u64             slot     // raw bits; payload is caller's responsibility
}

// Build a Mutex pre-filled with `value` bits (0 = uninitialised).
const Mutex::new(value<u64>) Mutex* {
    m<Mutex> = new Mutex
    m.sem  = BatchSemaphore::new(1)
    m.slot = value
    return &m
}

// Guard handed back by lock(). MutexGuard::release re-permits the mutex.
mem MutexGuard {
    Mutex* m
}

// Build a guard for m.
const MutexGuard::new(m<Mutex>) MutexGuard {
    return new MutexGuard { m: m }
}

// Read the protected slot; caller is responsible for its lifetime.
MutexGuard::get() u64 {
    return this.m.slot
}

// Write the protected slot.
MutexGuard::set(value<u64>){
    this.m.slot = value
}

// Release the lock. Calling release twice is a logic error.
MutexGuard::release(){
    s<BatchSemaphore> = this.m.sem
    s.release(1)
}

// Acquire the lock. Returns (0, MutexGuard) on success or (Closed, empty
// guard) when the underlying semaphore was closed.
async Mutex::lock(){
    err<i32> = this.sem.acquire(1).await
    if err != 0 return err, new MutexGuard { m: null }
    return 0, MutexGuard::new(this)
}

