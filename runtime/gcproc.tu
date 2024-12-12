use std

// buf list 
WorkbufSize<i64> = 2048
BufObjsize<i64>  = 253
addrBits<i64> 	 = 48
cntBits<i64>     = 19
BufAlloc<i64>    = 32768
enable_runtimemalloc<i64> = 1
heapmin<u64> = 41943040
gcpercent<i64> = 0
default_heap_min<i64> = 41943040
sweep_min_heap_distance<i64> =  10485760
gc<Gc:> = null
gcphase<u32> = 0
worldsema<Sema:> = null

enum {
	GcAlways,
	GcHeap
}
mem SpanCache {
	MutexInter    lock
	Spanlist   free
	Spanlist   busy
}

mem MarkBits {
	u8*  u8p
	u8   mask
	u64 index
}
MarkBits::isMarked(){
	return (*this.u8p & this.mask) != 0
}
MarkBits::setMarked(){
	atomic.or8(this.u8p,this.mask)
}

mem Gc {
	i32 kind
	u32 n
	i64 now

	List full
	List empty
	i32  forced
	u64  marked
	u32  cycles
	SpanCache   spans
	Sema        startSema
	MutexInter  worldSeam

	u64 gc_trigger,heaplives
	u64 heapmarked
	i32 enablegc
	i64 markStartTime
}

fn get_sp()
fn get_di()
fn get_si()
fn get_dx()
fn get_cx()
fn get_r8()
fn get_r9()
fn get_bp()
fn get_ax()
fn get_bx()

fn gc_malloc(nbytes<u64>)
{
	if enable_runtimemalloc<i64> {
		return malloc(nbytes,0.(i8),1.(i8))
	}
	return std.malloc(nbytes)
}

//discard..
fn GC(){
	gc.start(GcAlways)
}
fn gc_mark(){}
fn gc_free(ptr<u64>){}
fn gc_init(){}
fn gc_realloc(p<u64*>, pbytes<u64> , nbytes<u64>){
	if !p {
        if nbytes < 0 {
			dief(*"[gc] realloc failed")
        }
        return gc_malloc(nbytes)
    }
    if nbytes < 0 {
        gc_free(p)
        return Null
    }
    newp<u64*> = gc_malloc(nbytes)
    std.memcpy(newp,p,pbytes)
    gc_free(p)
    return newp
}

Gc::start(kind<i32>)
{
	if !gc.enablegc return Null
	// this.forced = true
	if this.trigger(kind) != True {
		return True
	}
	dgc(*"--------------------------start:(%d) %d waiting:%d--------------\n",this.cycles, this.trigger(kind),sched.gcwaiting)

	// while this.trigger(kind) == True && sweepone() >= Null {
	// }
	this.startSema.lock()
	if this.trigger(kind) != True {
		debug(*"start got start sema unlock %d\n",std.gettid())
		this.startSema.unlock()
		return True
	}
	// debugcachegen()
	this.worldSeam.lock()
	dgc(*"trigger h:%d t:%d\n",gc.heaplives,gc.gc_trigger)
	dgc(*"Got GC lock %d---\n",this.cycles)
	this.stopSTW()

	this.gc0()
    this.startSTW()
	dgc(*"Free GC lock %d---\n",this.cycles)
	this.worldSeam.unlock()
	this.startSema.unlock()
	dgc(*"trigger end h:%d t:%d\n",gc.heaplives,gc.gc_trigger)
	debug(*"-----------------------------end(%d)----------------------\n",this.cycles)
}
Gc::gc0(){
	dgc(*"gc0 \n")
	for c<Core> = sched.allcores; c != Null ; c = c.link {
		fg<u32> = atomic.load(&c.local.flushGen)
		if fg != heap_.sweepgen {
			debugcachegen()
			warn(*"runtime cid:%d flushgen:%d  != sweepgen:%d\n",c.cid,fg,heap_.sweepgen)
			dief(*"p machce not flushed\n")
		}
	}
	this.markinit()
    now<u64> = std.ntime()
	this.finishsweep()
	this.cycles += 1
	this.startcycle()

    gcphase = _GCmark
	this.markroot()
	this.marktinys()
	atomic.store(&gcBlackenEnabled,1.(i8))
	this.markStartTime = now
    this.markscan()
    this.markdone()
	dgc(*"gc0 done\n")
}

Gc::markdone()
{
	debug(*"markdone phase:%d\n",_GCmark)
	if( gcphase != _GCmark ){
		return True
	}
	for c<Core> = sched.allcores ; c != Null; c = c.link
		c.queue.dispose()
	atomic.store(&gcBlackenEnabled,0.(i8))

	this.markterm()
}

Gc::markterm()
{
	debug(*" start markterm\n")
	atomic.store(&gcBlackenEnabled, false)
	atomic.store(&gcphase,_GCmarktermination)
	for c<Core> = sched.allcores ; c != Null ; c = c.link {
		queue<Queue> = &c.queue	
		if queue.empty() == False {
			warn(*"wb1.nobj:%d wb2.nobj:%d\n",queue.buf1.nobj,queue.buf2.nobj)
			dief(*"M has cached gc work atg end of mark termination\n")
		}
	}
	gc.heapmarked = this.marked
	gc.heaplives = this.marked
	atomic.store(&gcphase,_GCoff)
	this.sweep()
	// checkalldead()
	// this.setratio(next_trigger_ratio)
	this.setratio()

	for c<Core> = sched.allcores; c != Null ; c = c.link {
		c.local.releaseAll()
	}
}


Gc::setratio(){
    trigger<i64> = -1
	if  gcpercent >= 0 {
		trigger = this.heapmarked * 2
        min_trigger<u64> = heapmin
		if heap_.isSweepDone() == False {
			sweep_min<u64> = atomic.load64(&this.heaplives)
            sweep_min += (sweep_min_heap_distance * gcpercent) / 100
			if sweep_min > min_trigger {
				min_trigger = sweep_min
			}
		}
		if trigger < min_trigger {
			trigger = min_trigger
		}
		if trigger < 0 {
			dief(*"gc_trigger underflow\n")
		}
	}
	this.gc_trigger = trigger
}

Gc::setpercent(in<i32>){
	heap_.lock.lock()
	out<i32> = gcpercent
	if(in < 0 ){
		in = -1
	}
	gcpercent = in
	heapmin = default_heap_min * gcpercent / 100

    this.setratio()
	heap_.lock.unlock()

    return out
}


Gc::stopSTW() {
	dgc(*"stop world \n")
    c<Core> = core()
    // debug_alllock()
    sched.lock.lock()
    // checkalldead()
    sched.stopwait = sched.cores
    allcores<i32> = sched.cores
    sched.stopmark = 0
    sched.stopsweep = 0
    atomic.store(&sched.gcwaiting,1.(i8))

    c.status = CoreStop
    sched.stopwait -= 1
    wait<i32> = sched.stopwait
    sched.lock.unlock()
    if(sched.stopwait > 0) {
        sched.stopnote.Sleep()
        sched.stopnote.Clear()
        // checkalldead()
	}
    if sched.stopwait > 0 {
        // checkalldead()
        dief(*"sched.stopwait:%d != 0 m:%d\n",sched.stopwait,sched.cores)
    }
    for c = sched.allcores; c != Null ; c = c.link {
        if c.status != CoreStop {
            checkalldead()
            dief(*"m.status not stop plan:%d now:%d\n",allcores,sched.cores)
        }
	}
    dgc(*"all world stop\n")
}
Gc::startSTW()
{
	dgc(*"start wolrd\n")
    c_<Core> = core()
    c_.status = CoreRun
    sched.gcwaiting = 0
    // checkalldead()
    for c<Core> = sched.allcores; c != Null ; c = c.link {
        if c.cid == c_.cid continue

        if c.status != CoreStop
            dief(*"m.status not stop\n")
        if c.status != CoreStop
            dief(*"thread:%d cur:%d not sleep\n",c.cid,core().cid)
        c.status = CoreRun
        c.park.Wake()
	} 
}
