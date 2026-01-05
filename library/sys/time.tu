use os

NSEC_PER_SEC<u64> = 1000000000

mem Timespec {
    i64 tv_sec
    u32 tv_nsec
}

const Timespec::new(tv_sec<i64>, tv_nsec<i64>)  Timespec {
    if tv_sec < 0 || tv_nsec >= NSEC_PER_SEC {
        runtime.printf("Timespec::new failed input")
        os.exit(-1)
    }
    // SAFETY: The assert above checks tv_nsec is within the valid range
    return Timespec { 
        tv_sec: tv_sec,
        tv_nsec: tv_nsec,
    }
}

Timespec::cmp(other<Timespec>) i32 {
    if this.tv_sec > other.tv_sec  return true

    if this.tv_sec < other.tv_nsec return false

    if this.tv_nsec >= other.tv_nsec return true
    return false
}

Timespec::sub_timespec(other<Timespec>) i32, Duration {
    if this.cmp(other) {
        secs<i64> = 0
        nsec<i32> = 0
        if this.tv_nsec >= other.tv_nsec {
            secs = this.tv_sec - other.tv_sec
            nsec = this.tv_nsec - other.tv_nsec
        } else {
            secs = this.tv_sec - other.tv_sec - 1
            nsec = this.tv_nsec + NSEC_PER_SEC - other.tv_nsec
        }
        return Ok , Duration::new(secs,nsec)
    } else {
        ok<i32> , d<Duration> = other.sub_timespec(this)
        return ok, d
    }
}

Timespec::checked_add_duration(other<Duration>) i32, Timespec {
    erri32, secs<i64> = this.tv_sec.checked_add_unsigned(other.as_secs())
    if  err != Ok return err

    // Nano calculations can't overflow because nanos are <1B which fit
    // in a u32.
    nsec<u32> = other.subsec_nanos() + this.tv_nsec
    if nsec >= NSEC_PER_SEC {
        nsec -= NSEC_PER_SEC
        err , secs = secs.checked_add(1)
        if err != Ok return err
    }
    return Has, Timespec::new(secs, nsec)
}

Timespec::from(t<std.TimeSpec> ) Timespec {
    return Timespec::new(t.tv_sec, t.tv_nsec)
}


mem Instant {
    Timespec* t
}

Instant::now() Instant {
    clock_id<i32> = CLOCK_MONOTONIC
    return new Instant { 
        t: Timespec::now(clock_id) 
    }
}

Instant::checked_sub_instant(other<Instant>) i32 ,Duration {
    err<i32> ,d<Duration> = this.t.sub_timespec(other.t)
    
    return err, d
}

Instant::checked_add_duration(other<Duration>) i32,Instant {
    err<i32> , t<TimeSpec> = this.t.checked_add_duration(other)
    if err != Ok return err

    return Has, new Instant {
        t: t
    }
}

Instant::duration_since(earlier<Instant>) Duration {
    err<i32> ,d<Duration> = this.checked_duration_since(earlier)
    if err != Ok return Duration::new(0,0)

    return err, d
}

Instant::checked_duration_since(earlier<Instant>)  i32 , Duration {
    err<i32> , d<Duration> = this.checked_sub_instant(earlier)
    return err, d
}

const Instant::elapsed() Duration {
    return Instant::now().duration_since(this)
}

const Instant::far_future()  Instant {
    return Instant::add(
        Instant::now(),
        Duration::from_secs(86400 * CLOCK_YEAR_DAYS * 30)
    )
}

const Instant::add(s<Instant> , dur<Duration>) Instant {
    has<i32> , inst<Instant> = s.checked_add(dur).expect("overflow when adding duration to instant")
    if has != Has {
        runtime.dief("overflow when adding duration to instant")
    }
    return inst
}

Instant::checked_add(duration<Duration>) i32,Instant {
    has<i32>,ret<Instant> = this.checked_add_duration(duration)
    return has,ret
}

mem Nanoseconds {
    u32 inner 
}

mem Duration {
    u64 secs
    Nanoseconds nanos // Always 0 <= nanos < NANOS_PER_SEC
}

SECOND<Duration:> = new Duration{
    secs: 1,
    nanos: 0,
}
MILLISECOND<Duration:> = new Duration{
    secs: 0,
    nanos: NANOS_PER_MILLI % NANOS_PER_SEC,
};
MICROSECOND<Duration:> = new Duration {
    secs: 0,
    nanos: NANOS_PER_MICRO % NANOS_PER_SEC,
}
NANOSECOND<Duration:> = new Duration{
    secs: 0 ,
    nanos: 1,
}
ZERO<Duration:> = new Duration{
    secs: 0 ,
    nanos: 0,
}
MAX<Duration:> = new Duration {
    secs: runtime.U64_MAX,
    nanos: 0
}

fn u64_checked_add(a<u64>, b<u64>) u64 {
    if runtime.U64_MAX - a < b {
        runtime.dief("overflow in u64 checkd add")
    }
    return a + b
}
const Duration::new(secs<u64>, nanos<u32>)  Duration {
    secs = u64_checked_add(secs,nanos / NANOS_PER_SEC)
    nanos = nanos % NANOS_PER_SEC
    // SAFETY: nanos % NANOS_PER_SEC < NANOS_PER_SEC, therefore nanos is within the valid range
    return new Duration { 
        secs: secs, 
        nanos: nanos 
    }
}
const Duration::from_secs(secs<u64>) Duration {
    return Duration::new(secs, 0)
}
const Duration::from_millis(millis<u64>) Duration {
    return Duration::new(millis / MILLIS_PER_SEC, (millis % MILLIS_PER_SEC) * NANOS_PER_MILLI)
}
const Duration::from_micros(micros<u64>) Duration {
    return Duration::new(micros / MICROS_PER_SEC, (micros % MICROS_PER_SEC) * NANOS_PER_MICRO)
}
const Duration::from_nanos(nanos<u64>) Duration {
    return Duration::new(nanos / NANOS_PER_SEC, nanos % NANOS_PER_SEC)
}

Duration::as_secs() u64 {
    return this.secs
}

Duration::subsec_nanos()  u32 {
    return this.nanos.inner
}
Duration::as_millis()  u64 {
    return this.secs  * MILLIS_PER_SEC + (this.nanos.inner / NANOS_PER_MILLI)
}

Duration::as_nanos() u64 {
    return this.secs * NANOS_PER_SEC + this.nanos.inner
}

