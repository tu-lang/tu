use os
use std
use runtime

NSEC_PER_SEC<u64> = 1000000000

fn i64_checked_add(a<i64>, b<i64>) i32, i64 {
    if b > 0 && a > runtime.I64_MAX - b {
        return Err, 0
    }
    if b < 0 && a < runtime.I64_MIN - b {
        return Err, 0
    }
    return Ok, a + b
}

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
    return new Timespec { 
        tv_sec: tv_sec,
        tv_nsec: tv_nsec,
    }
}

const Timespec::now(clock_id<i32>) Timespec {
    raw<std.TimeSpec> = new std.TimeSpec {}
    std.clock_gettime(clock_id, &raw)
    return Timespec::new(raw.sec, raw.nsec)
}

Timespec::cmp(other<Timespec>) i32 {
    if this.tv_sec > other.tv_sec return 1

    if this.tv_sec < other.tv_sec return 0

    if this.tv_nsec >= other.tv_nsec return 1
    return 0
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

const Duration::secs_raw(d<Duration>) u64 {
    return d.secs
}

const Duration::subsec_bits(d<Duration>) u32 {
    return d.subsec_nano.bits
}

const Duration::secs_i64(d<Duration>) i64 {
    raw<u64> = Duration::secs_raw(d)
    return raw.(i64)
}

Timespec::checked_add_duration(dur<Duration>) i32, Timespec {
    err<i32>, secs<i64> = i64_checked_add(this.tv_sec, Duration::secs_i64(dur))
    if err != Ok return err, null

    nsec<u32> = Duration::subsec_bits(dur) + this.tv_nsec
    if nsec >= NSEC_PER_SEC {
        nsec -= NSEC_PER_SEC
        err, secs = i64_checked_add(secs, 1)
        if err != Ok return err, null
    }
    return Has, Timespec::new(secs, nsec)
}

Timespec::from(ts<std.TimeSpec> ) Timespec {
    return Timespec::new(ts.sec, ts.nsec)
}


mem Instant {
    Timespec* when
}

const Instant::now() Instant {
    clock_id<i32> = CLOCK_MONOTONIC
    return new Instant {
        when: Timespec::now(clock_id)
    }
}

Instant::checked_sub_instant(other<Instant>) i32 ,Duration {
    err<i32> ,d<Duration> = this.when.sub_timespec(other.when)

    return err, d
}

Instant::checked_add_duration(other<Duration>) i32,Instant {
    err<i32> , new_ts<Timespec> = this.when.checked_add_duration(other)
    if err != Ok return err, null

    return Has, new Instant {
        when: new_ts
    }
}

Instant::duration_since(earlier<Instant>) Duration {
    err<i32> ,d<Duration> = this.checked_duration_since(earlier)
    if err != Ok return Duration::new(0, 0)

    return d
}

Instant::checked_duration_since(earlier<Instant>)  i32 , Duration {
    err<i32> , d<Duration> = this.checked_sub_instant(earlier)
    return err, d
}

Instant::elapsed() Duration {
    return Instant::now().duration_since(this)
}

const Instant::far_future()  Instant {
    return Instant::add(
        Instant::now(),
        Duration::from_secs(86400 * CLOCK_YEAR_DAYS * 30)
    )
}

const Instant::add(s<Instant> , dur<Duration>) Instant {
    has<i32> , inst<Instant> = s.checked_add(dur)
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
    u32 bits
}

mem Duration {
    u64 secs
    Nanoseconds subsec_nano // Always 0 <= bits < NANOS_PER_SEC
}

SECOND<Duration:> = new Duration{
    secs: 1,
    subsec_nano: new Nanoseconds { bits: 0 },
}
MILLISECOND<Duration:> = new Duration{
    secs: 0,
    subsec_nano: new Nanoseconds { bits: NANOS_PER_MILLI % NANOS_PER_SEC },
}
MICROSECOND<Duration:> = new Duration {
    secs: 0,
    subsec_nano: new Nanoseconds { bits: NANOS_PER_MICRO % NANOS_PER_SEC },
}
NANOSECOND<Duration:> = new Duration{
    secs: 0 ,
    subsec_nano: new Nanoseconds { bits: 1 },
}
ZERO<Duration:> = new Duration{
    secs: 0 ,
    subsec_nano: new Nanoseconds { bits: 0 },
}
// Mother: Duration::new(u64::MAX, NANOS_PER_SEC - 1)
MAX<Duration:> = new Duration {
    secs: 18446744073709551615,
    subsec_nano: new Nanoseconds { bits: 999999999 },
}

U64_MAX_VAL<u64> = 18446744073709551615

fn u64_checked_add(a<u64>, b<u64>) u64 {
    if U64_MAX_VAL - a < b {
        runtime.dief("overflow in u64 checkd add")
    }
    return a + b
}
const Duration::new(secs<u64>, nano_count<u32>)  Duration {
    secs = u64_checked_add(secs, nano_count / NANOS_PER_SEC)
    rem<u32> = nano_count % NANOS_PER_SEC
    // SAFETY: rem < NANOS_PER_SEC, therefore bits is within the valid range
    return new Duration {
        secs: secs,
        subsec_nano: new Nanoseconds { bits: rem },
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
    return this.subsec_nano.bits
}
Duration::as_millis()  u64 {
    return this.secs  * MILLIS_PER_SEC + (this.subsec_nano.bits / NANOS_PER_MILLI)
}

Duration::as_nanos() u64 {
    return this.secs * NANOS_PER_SEC + this.subsec_nano.bits
}

