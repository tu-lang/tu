Null<i64> = 0
# array
ARRAY_SIZE<i8>  = 8


CLOCK_REALTIME<i32>			  = 0
CLOCK_MONOTONIC<i32> 		  = 1
CLOCK_PROCESS_CPUTIME_ID<i32> = 2
CLOCK_THREAD_CPUTIME_ID<i32>  = 3
CLOCK_MONOTONIC_RAW<i32>      = 4
CLOCK_REALTIME_COARSE<i32>	  = 5
CLOCK_MONOTONIC_COARSE<i32>   = 6
CLOCK_BOOTTIME<i32> 		  = 7
CLOCK_REALTIME_ALARM<i32> 	  = 8
CLOCK_BOOTTIME_ALARM<i32>     = 9
CLOCK_SGI_CYCLE<i32> 		  = 10
CLOCK_TAI<i32>		 		  =	11

mem TimeSpec {
	i64 sec,nsec
}

seed<i64>
func stdinit(){
	seed = time()
	initmalloc()
}
