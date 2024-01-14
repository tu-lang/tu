fn gcinit(){
	heap_.sweepdone = 1
	//GCTODO:
	//gc.heapmarked = heapmin / 2
	//gc.setpercent(100.(i8))
	gc.startSema.sema = 1
	worldsema.sema = 1

	gc.enablegc = true
}

Gc::startcycle(){
	//GCTODO:
	//if this.gc_trigger <= heapmin {
//		this.heapmarked = this.gc_trigger / 2
	//}
	
}
Gc::trigger(kind<i32>){
	if !gc.enablegc {
		return False
	}
	if kind == GcAlways {
		return True
	}
	if gcphase != _GCoff {
		return False
	}
	match kind {
		GcHeap: return gc.heaplives >= gc.gc_trigger
		_ : 	return True
	}
}

Gc::markinit(){
	heap_.locks.lock()
	//GCTODO:
	arenas<std.Array> = heap_.allarenas
	heap_.locks.unlock()

	for i<i32> = 0 ; i < arenas.used ; i += 1 {
		ai<u32*> = &arenas.addr[i]
		l2<std.Array> = heap_.arenas[arena_l1(*ai)]
		ha<HeapArena> = l2.addr[arena_l2(*ai)]

		total<i64> = pagesPerArena / 8
		for j<i32> = 0 ; j < total ; j += 1{
			ha.pageMarks[j] = 0
		}
	}
	gc.marked = 0
}
Gc::finishsweep(){
	while sweepone() >= Null {
	}

	gbArenas.locks.lock()
	if gbArenas.previous != Null {
		if gbArenas.free == Null {
			gbArenas.free = gbArenas.previous
		}else{
			last<GcBitsArena> = gbArenas.previous
			for(last = gbArenas.previous; last.next != Null; last = last.next){
			}
			last.next = gbArenas.free
			gbArenas.free = gbArenas.previous
		}	
	}

	gbArenas.previous = gbArenas.current
	gbArenas.current = gbArenas.next
	atomic.store64(&gbArenas.next,Null)
	gbArenas.locks.unlock()
}
fn gcmarkhelper(){
	c<Core> = core()
	//GCTODO:
	//gc.markscan2(&c.queue)
	
	if atomic.xadd(&sched.stopmark, 1.(i8)) == sched.cores
		sched.allmarkdone.Wake()
}
fn gcsweephelper(){
    while sweepone() >= Null {}

	if atomic.xadd(&sched.stopsweep, 1.(i8)) == sched.cores
		sched.allsweepdone.Wake()
}