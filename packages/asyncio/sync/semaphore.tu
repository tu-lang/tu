// User-facing semaphore. Thin wrapper over BatchSemaphore with a Permit
// guard so calls form RAII-shaped sites in user code. No Drop in TuLang —
// callers must release / forget explicitly.

// Counting semaphore with FIFO fairness.
mem Semaphore {
    BatchSemaphore* sem
}

// Build a Semaphore with n permits.
const Semaphore::new(n<u32>) Semaphore* {
    s<Semaphore> = new Semaphore
    s.sem = BatchSemaphore::new(n)
    return &s
}

// Permit handed back by acquire(); release() returns the permit, forget()
// drops it.
mem Permit {
    Semaphore* parent
    u32        n          // permit count this guard holds
}

// Build a permit holding `n` slots of parent.
const Permit::new(parent<Semaphore>, n<u32>) Permit {
    return new Permit { parent: parent, n: n }
}

// Return the held permits to the parent.
Permit::release(){
    if this.parent == null return
    s<BatchSemaphore> = this.parent.sem
    s.release(this.n)
    this.parent = null
}

// Drop the permits without returning them. Useful for one-shot bursts.
Permit::forget(){
    this.parent = null
}

// Acquire n permits. Returns (0, Permit) or (Closed, empty Permit).
async Semaphore::acquire(n<u32>){
    err<i32> = this.sem.acquire(n).await
    if err != 0 return err, new Permit { parent: null, n: 0 }
    return 0, Permit::new(this, n)
}

// Non-blocking variant; returns SendFull when permits are unavailable.
Semaphore::try_acquire(n<u32>) (i32, Permit) {
    err<i32> = this.sem.try_acquire(n)
    if err != 0 return err, new Permit { parent: null, n: 0 }
    return 0, Permit::new(this, n)
}

// Mark the semaphore closed; pending and future acquire calls bail out.
Semaphore::close(){
    this.sem.close()
}

