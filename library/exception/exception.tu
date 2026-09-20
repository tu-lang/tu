// Dynamic Exception base (L2b). Language surface; class in static library.
// Class methods are dyn defs — static debug/runtime calls go through export or unsafe.

use std
use runtime
use runtime.debug

class Exception {
	message = ""
	code = 0
	file = ""
	line = 0
	trace = []
	previous = null

	func init(msg){
		this.message = msg
		this.code = 0
		exception_fill_throw_site(this)
	}
	func getMessage(){
		return this.message
	}
	func getCode(){
		return this.code
	}
	func getFile(){
		return this.file
	}
	func getLine(){
		return this.line
	}
	func getTrace(){
		if std.len(this.trace) == 0 {
			exception_refresh_trace(this)
		}
		return this.trace
	}
	func getTraceAsString(){
		s = ""
		for f : this.getTrace() {
			s += f
			s += "\n"
		}
		return s
	}
	func getPrevious(){
		return this.previous
	}
	func setPrevious(p){
		this.previous = p
	}
}

// Fill file/line/trace/previous from the throw site (skip Exception::init frames).
export func exception_fill_throw_site(ex) {
	ex.file = debug.CallerFile(3)
	ex.line = debug.CallerLine(3)
	ex.trace = debug.stack(32)
	ex.previous = null
	if runtime.exc_nest() > 0 {
		cause = runtime.exc_current_obj()
		if cause != null {
			ex.previous = cause
		}
	}
}

export func exception_refresh_trace(ex) {
	ex.trace = debug.stack(32)
}

// Install global uncaught handler bits; returns previous handler bits.
export func setExceptionHandler(h){
	return runtime.set_exception_handler(h.(u64))
}
