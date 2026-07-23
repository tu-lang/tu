// sys.Duration from_millis / as_millis round-trip (flat nanos field).
use fmt
use os
use sys

fn main() {
    d<sys.Duration> = sys.Duration::from_millis(50)
    ms<u64> = d.as_millis()
    if ms != 50 {
        fmt.println("from_millis(50) as_millis mismatch")
        fmt.println(int(ms))
        os.exit(1)
    }
    d2<sys.Duration> = sys.Duration::from_millis(1500)
    if d2.as_secs() != 1 {
        fmt.println("from_millis(1500) secs mismatch")
        os.exit(1)
    }
    if d2.as_millis() != 1500 {
        fmt.println("from_millis(1500) as_millis mismatch")
        fmt.println(int(d2.as_millis()))
        os.exit(1)
    }
    fmt.println("duration_millis passed")
}
