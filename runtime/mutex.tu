use std.atomic

mem MutexInter {
   u32 key
}
mem SemaWaiter {
   u32* addr
   u64* c
   i64 releasetime
   i32 nrelease
   SemaWaiter* prev
   SemaWaiter* next
}

mem SemaRoot {
   MutexInter  lock
   SemaWaiter* head
   SemaWaiter* tail
   u32 nwait
}

mem SemTable {
   SemaRoot root
   u8 _pad[32]
}

mem Sema {
   u32 sema
}
Sema::init(){
    this.sema = 1
}
mem Mutex {
   i32 state 
   Sema sema
}

mem Note{
   u32 key
}
Mutex::init(){}
Mutex::lock(){
    if atomic.cas(&this.state,Null,MutexLocked) != Null {
        return Null
    }
    awoke<i32> = 0

    loop {
        old<i32> = this.state
        newo<i32> = old | MutexLocked
        if (old & MutexLocked) != 0 {
            newo = old + (1 << MutexWaiterShift)
        }
        if awoke > 0 {
            newo &= ~MutexWoken
        }
        if atomic.cas(&this.state,old,newo) != Null {
            if (old & MutexLocked) == 0
                break
            this.sema.lock()
            awoke = 1
        }
    }
}
Mutex::unlock(){
    newo<i32> = atomic.xadd(&this.state,0 - MutexLocked)
    if ((newo + MutexLocked) &MutexLocked ) == 0  {
        dief(*"sync: unlock of unlockded mutex")
    }
    old<i32> = newo
    loop {
        if ( (old>>MutexWaiterShift) == 0 )|| ((old&(MutexLocked|MutexWoken)) != 0 ) {
            return Null
        }
        newo = (old - 1<<MutexWaiterShift) | MutexWoken
        if atomic.cas(&this.state,old,newo) != Null {
            this.sema.unlock()
            return Null
        }
        old = this.state
    }
}


Sema::Semroot(){
    semaaddr<u64> = &this.sema
    //sema<SemTable> = &semtable[(semaaddr >> 3) % 251]
    //return sema.root
}

Sema::trylock(){
    loop {
        v<u32> = atomic.load(&this.sema)
        if v == 0  return Null
        if atomic.cas(&this.sema,v,v - 1)
            return 1.(i8)
    }
}
Sema::lock(){
    s<SemaWaiter> = new SemaWaiter
    if this.trylock() != Null return Null
    reduce<i32> = -1

    root<SemaRoot> = this.Semroot()
    
    loop {
        root.lock.lock()
        atomic.xadd(&root.nwait,1.(i8))

        if this.trylock() != Null {
            atomic.xadd(&root.nwait,reduce)
            root.lock.unlock()
            return Null
        }
        root.queue(&this.sema,s)
        parkunlock(&root.lock)
        if this.trylock() != Null {
            return Null
        }
    }
}
Sema::unlock()
{
    s<SemaWaiter> = null
    root<SemaRoot> = this.Semroot()
    atomic.xadd(&this.sema,1.(i8))

    if atomic.load(&root.nwait) == Null {
        return Null
    }
    root.lock.lock()
    if atomic.load(&root.nwait) == Null {
        root.lock.unlock()
        return Null
    }
    for s = root.head ; s != null ; s = s.next {
        if s.addr == &this.sema {
            atomic.xadd(&root.nwait,-1.(i8))
            root.dequeue(s)
            break
        }
    }

    root.lock.unlock()
}

SemaRoot::queue(addr<u32*> , s<SemaWaiter>){
    s.c = core()

    s.addr = addr
    s.next = Null
    s.prev = this.tail

    if this.tail != null
        this.tail.next = s
    else   
        this.head = s
    this.tail = s
}

SemaRoot::dequeue(s<SemaWaiter>){
    if(s.next)
        s.next.prev = s.prev
    else   
        this.tail = s.prev
    if(s.prev)
        s.prev.next = s.next
    else
        this.head = s.next

    s.prev = Null
    s.next = Null
}

fn canspin(i<i32>){
    if i >= active_spin || ncpu <= 1 {
        return 0.(i8)
    }
    return 1.(i8)
}
MutexInter::init(){}
MutexInter::lock(){
    //GCTODO: coredump here need fix tls
    return Null
    c<Core> = core()
    c.locks += 1
    if c.locks < 0 {
        dief(*"runtime lock: lock count %d",c.locks)
    }

    v<u32> = atomic.xchg(&this.key,mutex_locked)
    if v == mutex_unlocked {
        return Null
    }
    wait<u32> = v

    spin<u32> = 0
    if  ncpu > 1 {
        spin = active_spin
    }
    loop {
        for i<i32> = 0 ; i < spin ; i += 1 {
            while this.key == mutex_unlocked {
                if atomic.cas(&this.key,mutex_unlocked,wait) != Null
                    return Null
            }
            procyield(active_spin_cnt)
        }
    }
    for j<i32> = 0 ; j < passive_spin ; j += 1 {
        while this.key == mutex_unlocked {
            if atomic.cas(&this.key,mutex_unlocked,wait) != Null
                return Null
        }
        osyield()
    }

    v = atomic.xchg(&this.key,mutex_sleeping)
    if v == mutex_unlocked {
        return Null
    }

    wait = mutex_sleeping
    futexsleep(&this.key,mutex_sleeping,-1.(i8))
}

MutexInter::unlock(){
    //GCTODO: coredump here,need fix tls
    return Null
    c<Core> = core()
    v<u32> = atomic.xchg(&this.key,mutex_unlocked)
    if v == mutex_unlocked {
        dief(*"unlock of unlocked lock key:%d v:%d",this.key,v)
    }
    if  v == mutex_sleeping {
        futexwakeup(&this.key,1.(i8))
    }

    c.locks -= 1
    if c.locks < 0 {
        dief(*"runtime:unlock lock count(%d) < 0",c.locks)
    }
}

Note::Wake(){
	old<u32> = atomic.xchg(&this.key, 1.(i8))
	if old != 0 {
		dief(*"notewakeup - double wakeup (%d)", old)
	}
    futexwakeup(&this.key, 1.(i8))
}
Note::Sleep(){
	while atomic.load(&this.key) == Null {
		futexsleep(&this.key, 0.(i8), -1.(i8))
	}
}
Note::Clear()
{
	this.key = 0
}