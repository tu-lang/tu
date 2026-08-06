// L2b/L2c exception engine: TLS try/defer stacks + setjmp/longjmp.
// Jmpbufs are 64-byte stack slots owned by each try (must not move / GC).
// L2a (die/SEGV) must never call into this module.

use std
use fmt
use os

EXC_MAX_NEST<i32> = 32

// DeferNode: fnptr==0 is a function-frame sentinel (prologue push).
mem DeferNode {
	u64 fnptr
	DeferNode* prev
}

// TryFrame metadata; jmpbuf_ptr points at caller stack slot (64 bytes).
mem TryFrame {
	u64 jmpbuf_ptr
	u64 catch_type
	DeferNode* defer_mark
	i32 has_finally
	i32 unwinding
	TryFrame* prev
}

mem ExcState {
	TryFrame* tries
	DeferNode* defers
	u64 cur_exc
	i32 nest
	u64 uncaught
}

g_exc_ready<i32> = 0
g_exc<ExcState> = null

fn exc_ensure() ExcState {
	if g_exc_ready != 0 {
		return g_exc
	}
	g_exc = new ExcState{
		tries: null,
		defers: null,
		cur_exc: 0.(u64),
		nest: 0,
		uncaught: 0.(u64),
	}
	g_exc_ready = 1
	return g_exc
}

fn exc_try_push(catch_type<u64>, has_finally<i32>, jmpbuf<u64>) TryFrame {
	st<ExcState> = exc_ensure()
	tf<TryFrame> = new TryFrame{
		jmpbuf_ptr: jmpbuf,
		catch_type: catch_type,
		defer_mark: st.defers,
		has_finally: has_finally,
		unwinding: 0,
		prev: st.tries
	}
	st.tries = tf
	return tf
}

fn exc_try_pop() {
	st<ExcState> = exc_ensure()
	if st.tries == null {
		return
	}
	st.tries = st.tries.prev
}

fn exc_jmpbuf_ptr(tf<TryFrame>) u64 {
	return tf.jmpbuf_ptr
}

fn defer_frame_push() {
	st<ExcState> = exc_ensure()
	n<DeferNode> = new DeferNode{
		fnptr: 0.(u64),
		prev: st.defers
	}
	st.defers = n
}

fn defer_push(fnptr<u64>) {
	st<ExcState> = exc_ensure()
	n<DeferNode> = new DeferNode{
		fnptr: fnptr,
		prev: st.defers
	}
	st.defers = n
}

fn defer_thunk() {
	return
}

fn call_defer_fn(p<u64>) {
	if p == 0.(u64) {
		return
	}
	fc<defer_thunk> = p.(u64)
	fc()
}

fn defer_run_frame() {
	st<ExcState> = exc_ensure()
	while st.defers != null {
		n<DeferNode> = st.defers
		st.defers = n.prev
		if n.fnptr == 0.(u64) {
			return
		}
		call_defer_fn(n.fnptr)
	}
}

fn defer_run_until(mark<DeferNode>) {
	st<ExcState> = exc_ensure()
	while st.defers != null && st.defers != mark {
		n<DeferNode> = st.defers
		st.defers = n.prev
		if n.fnptr != 0.(u64) {
			call_defer_fn(n.fnptr)
		}
	}
}

fn defer_run_all() {
	defer_run_frame()
}

fn set_exception_handler(h<u64>) u64 {
	st<ExcState> = exc_ensure()
	old<u64> = st.uncaught
	st.uncaught = h
	return old
}

fn exc_current() u64 {
	return exc_ensure().cur_exc
}

fn exc_nest() i32 {
	return exc_ensure().nest
}

// Dyn helper: return in-flight exception as object Value* (or null).
func exc_current_obj(){
	bits<u64> = exc_current()
	if bits == 0.(u64) {
		return null
	}
	v<Value> = bits.(Value)
	return v
}

fn exc_set_current(obj<u64>) {
	exc_ensure().cur_exc = obj
}

fn call_handler(p<u64>, obj<u64>) {
	if p == 0.(u64) {
		return
	}
	fc<handler_thunk> = p.(u64)
	fc(obj)
}

fn handler_thunk(obj<u64>) {
	return
}

fn exc_throw(obj<u64>) {
	st<ExcState> = exc_ensure()
	if st.nest >= EXC_MAX_NEST {
		os.dief("exception nest depth exceeded")
	}
	st.cur_exc = obj
	st.nest = st.nest + 1
	if st.tries == null {
		exc_uncaught(obj)
		return
	}
	tf<TryFrame> = st.tries
	// Throw from finally/defer while this frame is already unwinding:
	// abandon this handler and propagate to the outer try.
	if tf.unwinding != 0 {
		st.tries = tf.prev
		if st.tries == null {
			exc_uncaught(obj)
			return
		}
		tf = st.tries
	}
	tf.unwinding = 1
	defer_run_until(tf.defer_mark)
	buf<u64> = exc_jmpbuf_ptr(tf)
	longjmp(buf, 1)
}

fn exc_uncaught(obj<u64>) {
	st<ExcState> = exc_ensure()
	if st.uncaught != 0.(u64) {
		h<u64> = st.uncaught
		st.uncaught = 0.(u64)
		call_handler(h, obj)
	}
	os.dief("uncaught exception")
}

fn exc_rethrow() {
	st<ExcState> = exc_ensure()
	obj<u64> = st.cur_exc
	if st.tries == null {
		exc_uncaught(obj)
		return
	}
	tf<TryFrame> = st.tries
	tf.unwinding = 1
	defer_run_until(tf.defer_mark)
	buf<u64> = exc_jmpbuf_ptr(tf)
	longjmp(buf, 1)
}

// Match dynamic exception against catch type.
// want_hdr==0 means catch any; otherwise want_hdr is virth_* address.
// Walks ObjectValue.hdr parent chain (class objects).
fn exc_catch_match(want_hdr<u64>, obj<u64>) i32 {
	if obj == 0.(u64) {
		return 0
	}
	if want_hdr == 0.(u64) {
		return 1
	}
	v<Value> = obj.(Value)
	if v.type != Object {
		return 0
	}
	ov<ObjectValue> = obj.(ObjectValue)
	if ov.hdr == null {
		return 0
	}
	hdr<VObjHeader> = ov.hdr
	while hdr != null {
		if hdr.(u64) == want_hdr {
			return 1
		}
		if hdr.parent == 0.(u64) {
			break
		}
		hdr = hdr.parent.(VObjHeader)
	}
	return 0
}

fn exc_clear_nest() {
	st<ExcState> = exc_ensure()
	if st.nest > 0 {
		st.nest = st.nest - 1
	}
	st.cur_exc = 0.(u64)
}
