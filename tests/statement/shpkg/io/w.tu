// Nested package short name is `io`; bare `use io` binds library without
// poisoning local package globals (ERROR) or types (Sink / Writer).
use io

// Local global: must mangle as shpkg_io_ERROR, not library io_ERROR.
ERROR<i32> = 0x10
LOCAL_OK<i32> = 7

api Writer {
    fn write_n() (i32)
}

mem Sink {
    i32 x
}

impl Writer for Sink {
    fn write_n() i32 {
        // Local globals still resolve after bare `use io`.
        if ERROR != 0x10 {
            return -2
        }
        // Library package const via imported short name.
        if io.Ok != 1 {
            return -3
        }
        b<io.Buf> = io.NewBuf(4)
        if b == null {
            return -1
        }
        return this.x + LOCAL_OK - 7
    }
}

fn make() Writer {
    s<Sink> = new Sink { x: 7 }
    w<Writer> = s
    return w
}
