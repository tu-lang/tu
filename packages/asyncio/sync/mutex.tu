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

// Guard handed back after acquire. MutexGuard::give_back re-permits the mutex.
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

// Cross-pkg / recommended acquire: build AcquireFut then await.
// Member async Mutex::lock is unsafe across packages (null assign / MT poison).
fn mutex_acquire_fut_bits(mutex_bits<u64>) AcquireFut {
    m<Mutex> = mutex_bits.(Mutex)
    fut<AcquireFut> = new AcquireFut{}
    fut.init(m.sem, 1)
    return fut
}

fn mutex_guard_from_bits(g_bits<u64>) MutexGuard {
    return g_bits.(MutexGuard)
}

fn mutex_guard_bits(mutex_bits<u64>) u64 {
    m<Mutex> = mutex_bits.(Mutex)
    return MutexGuard::new(m).(u64)
}

fn mutex_guard_set_bits(g_bits<u64>, v<u64>) {
    g<MutexGuard> = g_bits.(MutexGuard)
    g.set(v)
}

fn mutex_guard_get_bits(g_bits<u64>) u64 {
    g<MutexGuard> = g_bits.(MutexGuard)
    return g.get()
}

fn mutex_guard_give_back_bits(g_bits<u64>) {
    g<MutexGuard> = g_bits.(MutexGuard)
    g.give_back()
}
