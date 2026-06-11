// Lock: thin wrapper over runtime.MutexInter with the scheduler's vocabulary
// Related: packages-asyncio-runtime task 4.9, R12.1, R12.2, R12.3
// Design: design §12
//
// The wrapper exposes only lock() / unlock(); try_lock and re-entrancy are
// intentionally absent.  Schedulers always call into Lock through these two
// methods so future replacements (e.g. ticket / RW) are isolated.

use runtime

class Lock {
    inner   // runtime.MutexInter
}

Lock::init(){
    m<runtime.MutexInter> = new runtime.MutexInter
    m.init()
    this.inner = m
}

// lock(): block until the lock is acquired.  Not re-entrant.
Lock::lock(){
    m<runtime.MutexInter> = this.inner
    m.lock()
}

// unlock(): release the lock.  Caller must currently hold it.
Lock::unlock(){
    m<runtime.MutexInter> = this.inner
    m.unlock()
}
