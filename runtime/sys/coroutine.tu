use runtime.malloc
use std

mem Stack {
	u64	lo
	u64 hi
}


mem Coroutine {
    Core* 		m
	i8			preempt
	Stack       stk    
	u64     	stackguard0 
	u64 		stackguard1 
	i64 		gcAssistBytes
	MutexInter  locks
}

