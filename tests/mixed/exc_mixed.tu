// Mixed: static fn + mem + dynamic class interop for try/catch/defer/throw.

use fmt
use os
use exception

g_hit = 0
g_order = ""
g_mem_hits = 0

class DynThrower {
	func boom(){
		throw new exception.Exception("dyn")
	}
}

class DynCatcher {
	got = ""

	func catchStaticThrow(){
		this.got = ""
		try {
			mixed_static_throw()
		} catch (e) {
			this.got = e.getMessage()
		}
	}
}

mem StatSink {
	i32 hits
}

StatSink::reset(){
	this.hits = 0
}
StatSink::get(){
	return this.hits
}
StatSink::tryCatchMem(){
	hit = 0
	try {
		throw new exception.Exception("mem")
	} catch (e) {
		hit = 1
	}
	return hit
}
StatSink::deferMem(){
	g_mem_hits = 0
	this.deferMemInner()
	if g_mem_hits != 2 {
		os.die("defer mem want 2")
	}
}
StatSink::deferMemInner(){
	defer {
		g_mem_hits = g_mem_hits + 1
	}
	defer {
		g_mem_hits = g_mem_hits + 1
	}
}
StatSink::finallyWithDyn(){
	g_mem_hits = 0
	d = new DynThrower()
	try {
		d.boom()
	} catch (e) {
		g_mem_hits = g_mem_hits + 1
	} finally {
		g_mem_hits = g_mem_hits + 2
	}
}

sink<StatSink> = new StatSink{}

fn mixed_static_throw(){
	throw new exception.Exception("mixed")
}

fn test_static_catches_dyn(){
	fmt.println("test_static_catches_dyn")
	g_hit = 0
	d = new DynThrower()
	try {
		d.boom()
	} catch (e) {
		g_hit = 1
		if e.getMessage() != "dyn" {
			os.die("static catches dyn msg")
		}
	}
	if g_hit != 1 {
		os.die("static catches dyn")
	}
	fmt.println("test_static_catches_dyn passed")
}

fn test_dyn_catches_static(){
	fmt.println("test_dyn_catches_static")
	c = new DynCatcher()
	c.catchStaticThrow()
	if c.got != "mixed" {
		os.die("dyn catches static want mixed got " + c.got)
	}
	fmt.println("test_dyn_catches_static passed")
}

fn test_mem_try_catch(){
	fmt.println("test_mem_try_catch")
	if sink.tryCatchMem() != 1 {
		os.die("mem try catch")
	}
	fmt.println("test_mem_try_catch passed")
}

fn test_mem_defer(){
	fmt.println("test_mem_defer")
	sink.deferMem()
	fmt.println("test_mem_defer passed")
}

fn test_static_defer_then_dyn_throw(){
	fmt.println("test_static_defer_then_dyn_throw")
	g_order = ""
	mixed_defer_dyn()
	if g_order != "CD" {
		os.die("defer dyn want CD got " + g_order)
	}
	fmt.println("test_static_defer_then_dyn_throw passed")
}

fn mixed_defer_dyn(){
	defer {
		g_order += "D"
	}
	d = new DynThrower()
	try {
		d.boom()
	} catch (e) {
		g_order += "C"
	}
}

fn test_mem_finally_with_class(){
	fmt.println("test_mem_finally_with_class")
	sink.finallyWithDyn()
	if g_mem_hits != 3 {
		os.die("mem finally dyn want 3")
	}
	fmt.println("test_mem_finally_with_class passed")
}

fn main(){
	test_static_catches_dyn()
	test_dyn_catches_static()
	test_mem_try_catch()
	test_mem_defer()
	test_static_defer_then_dyn_throw()
	test_mem_finally_with_class()
	fmt.println("all mixed exc tests passed")
}
