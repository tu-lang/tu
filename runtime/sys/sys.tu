use std
use os
use runtime.malloc

gcBlackenEnabled<u32> = 0
gcphase<u32> = 0
ncpu<u32> = 0

allm<u64:10> = null

fn futexsleep(addr<u32*> , val<u32> , ns<i64>){
    if ns < 0 {
        futex(addr,FUTEX_WAIT,val,Null,Null,Null)
        return Null
    }
    ts<TimeSpec:> = null
    futex(addr,FUTEX_WAIT,val,&ts,Null,Null)
}
fn futexwakeup(addr<u32*> , cnt<u32>) {
    ret<i32> = futex(addr,FUTEX_WAKE,cnt,Null,Null,Null)
    if ret >= 0 {
        return Null
    }
    panic<i32*> = 0x1006
    *panic = 0x1006
}

func round(n<u64>,a<u64>)
{
    return (n + a - 1) &~ (a - 1)
}
func fastrand()
{
    g<Coroutine> = malloc.getg()
    mp<Core>  = g.m
    s1<u32> = 0
    s0<u32> = 0
    s1 = mp.fastrand[0]
    s0 = mp.fastrand[1]
    s1 ^= s1 << 17
    s1 = s1 ^ s0 ^ s1 >> 7 ^ s0 >> 16
    mp.fastrand[0] = s0
    mp.fastrand[1] = s1
    return s0 + s1
}
func ctz64(x<u64>)
{
    x &= 0 - x                      
    y<i32>  = x * deBruijn64 >> 58    
    i<i32>  = deBruijnIdx64[y]   
    z<i32>  = (x - 1) >> 57 & 64 
    return i + z
}

