// Thin wrapper over runtime.MutexInter with the scheduler's vocabulary.
// Only lock/unlock; no try_lock and not re-entrant.

use runtime

// Wraps a single MutexInter so future replacements (ticket / RW) stay isolated.
class Lock {
    inner   // runtime.MutexInter
}

// Create the underlying mutex.
Lock::init(){
    m<runtime.MutexInter> = new runtime.MutexInter
    m.init()
    this.inner = m
}

// Block until the lock is acquired. Not re-entrant.
Lock::lock(){
    m<runtime.MutexInter> = this.inner
    m.lock()
}

// Release the lock; caller must currently hold it.
Lock::unlock(){
    m<runtime.MutexInter> = this.inner
    m.unlock()
}
