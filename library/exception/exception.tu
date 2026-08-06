// Dynamic Exception base (L2b). Language surface; dyn class exemption: library/exception.

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
		// Throw site: skip Exception::init (+ new/super frames as needed).
		this.file = debug.CallerFile(2)
		this.line = debug.CallerLine(2)
		this.trace = debug.stack(32)
		this.previous = null
		if runtime.exc_nest() > 0 {
			cause = runtime.exc_current_obj()
			if cause != null {
				this.previous = cause
			}
		}
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
			this.trace = debug.stack(32)
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

// Install global uncaught handler bits; returns previous handler bits.
func setExceptionHandler(h){
	return runtime.set_exception_handler(h.(u64))
}
