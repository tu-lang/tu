// Async Mutex backed by BatchSemaphore(1). The guard re-permits via
// give_back(); callers must invoke MutexGuard::give_back explicitly because
// TuLang has no Drop.

// Async mutex over a u64 slot. Owners cast the slot via slot.(SomeMem).
mem Mutex {
    BatchSemaphore* sem
    u64             slot     // raw bits; payload is caller's responsibility
}

// Build a Mutex pre-filled with `value` bits (0 = uninitialised).
const Mutex::new(value<u64>) Mutex {
    m<Mutex> = new Mutex
    m.sem  = BatchSemaphore::new(1)
    m.slot = value
    return m
}

// Guard handed back by lock(). MutexGuard::give_back re-permits the mutex.
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

// Release the lock. Calling give_back twice is a logic error.
MutexGuard::give_back(){
    batch_sem_release(this.m.sem, 1)
}

// Acquire the lock. Returns (0, MutexGuard) on success or (Closed, empty
// guard) when the underlying semaphore was closed.
async Mutex::lock(){
    fut<AcquireFut> = new AcquireFut
    fut.init(this.sem, 1)
    err<i32> = fut.await
    if err != 0 return err, new MutexGuard { m: null }
    return 0, MutexGuard::new(this)
}
