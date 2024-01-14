use std

mem Coroutine {
    Core* 		m
	i8			preempt
	u64     	stackguard0 
	u64 		stackguard1 
	i64 		gcAssistBytes
	MutexInter  locks
}

