// User-facing semaphore. Thin wrapper over BatchSemaphore with a Permit
// guard so calls form RAII-shaped sites in user code. No Drop in TuLang —
// callers must give_back / forget explicitly.

// Counting semaphore with FIFO fairness.
mem Semaphore {
    BatchSemaphore* sem
}

// Build a Semaphore with n permits.
const Semaphore::new(n<u32>) Semaphore {
    s<Semaphore> = new Semaphore
    s.sem = BatchSemaphore::new(n)
    return s
}

// Permit handed back by acquire(); give_back() returns the permit, forget()
// drops it.
mem Permit {
    Semaphore* owner_sem
    u32        n          // permit count this guard holds
}

// Build a permit holding `n` slots of owner_sem.
const Permit::new(owner_sem<Semaphore>, n<u32>) Permit {
    return new Permit { owner_sem: owner_sem, n: n }
}

// Return the held permits to the owner semaphore.
Permit::give_back(){
    if this.owner_sem == null { return }
    batch_sem_release(this.owner_sem.sem, this.n)
    this.owner_sem = null
}

// Drop the permits without returning them. Useful for one-shot bursts.
Permit::forget(){
    this.owner_sem = null
}

// Acquire n permits. Returns (0, Permit) or (Closed, empty Permit).
async Semaphore::acquire(n<u32>){
    fut<AcquireFut> = new AcquireFut
    fut.init(this.sem, n)
    err<i32> = fut.await
    if err != 0 return err, new Permit { owner_sem: null, n: 0 }
    return 0, Permit::new(this, n)
}

// Cross-pkg: await AcquireFut leaf, then build Permit in the owner package.
fn semaphore_acquire_fut_bits(sem_bits<u64>, n<u32>) AcquireFut {
    s<Semaphore> = sem_bits.(Semaphore)
    fut<AcquireFut> = new AcquireFut{}
    fut.init(s.sem, n)
    return fut
}

fn semaphore_permit_bits(sem_bits<u64>, n<u32>) u64 {
    s<Semaphore> = sem_bits.(Semaphore)
    p<Permit> = Permit::new(s, n)
    return p.(u64)
}

fn permit_give_back_bits(p_bits<u64>) {
    p<Permit> = p_bits.(Permit)
    p.give_back()
}

// Non-blocking variant; returns SendFull when permits are unavailable.
Semaphore::try_acquire(n<u32>) (i32, Permit) {
    err<i32> = this.sem.try_acquire(n)
    if err != 0 return err, new Permit { owner_sem: null, n: 0 }
    return 0, Permit::new(this, n)
}

fn semaphore_try_acquire_bits(sem_bits<u64>, n<u32>) (i32, u64) {
    s<Semaphore> = sem_bits.(Semaphore)
    err<i32>, p<Permit> = s.try_acquire(n)
    if err != 0 return err, 0
    return 0, p.(u64)
}

// Mark the semaphore closed; pending and future acquire calls bail out.
Semaphore::close(){
    this.sem.close()
}
