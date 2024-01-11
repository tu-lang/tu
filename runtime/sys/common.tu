//FIXME: __thread  Coroutine* _g_;
use fmt
use std

CacheLinePadSize<i64>  = 64
Null<i64> = 0
STDOUT<i64> = 1
THREAD_STACK_SIZE<i64> = 32768
THREAD_TLS_SIZE<i64>   = 1024

// clone
SIGCHLD<i64>      		  = 0x11
CLONE_CHILD_CLEARTID<i64> = 0x00200000
CLONE_VM<i64>             = 0x100
CLONE_FS<i64>             = 0x200
CLONE_FILES<i64>          = 0x400
CLONE_SIGHAND<i64>        = 0x800
CLONE_SYSVSEM<i64>        = 0x40000
CLONE_THREAD<i64>         = 0x10000

// mutex
MutexLocked<i32> = 1
MutexWoken<i32>  = 2 
MutexWaiterShift<i32> = 3

semtable<SemTable:251> = null
mutex_unlocked<u32> = 0
mutex_locked<u32>   = 1
mutex_sleeping<u32> = 2

active_spin<i32> = 4
active_spin_cnt<i32> = 30
passive_spin<i32> = 1

// futex
FUTEX_PRIVATE_FLAG<i32> = 128
FUTEX_WAIT_PRIVATE<i32> = 128
FUTEX_WAKE_PRIVATE<i32> = 129
FUTEX_WAIT<i32> = 0
FUTEX_WAKE<i32> = 1

mem TimeSpec {
    i64 tv_sec
    i64 tv_nsec
}
TimeSpec::init(ns<i64>){
    this.tv_sec  = ns / 1000000000
    this.tv_nsec = ns % 1000000000
}

// impl by asm
fn osyield()
fn procyield(cnt<i64>)
fn futex(addr<u32*>,op<i32> ,val<u32>,ts<u64> ,addr2<u64>,val3<u32>)

func dief(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	fmt.vfprintf(STDOUT,str,arg1,arg2,arg3,arg4,arg5)
	std.die(-1.(i8))
}

func outf(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	fmt.vfprintf(STDOUT,str,arg1,arg2,arg3,arg4,arg5)
}