// TCP echo: async body lives in the test/example main file style via this
// package-level async — NOTE: imported-package await of Mem is broken, so
// tcpEcho is implemented in the test file; this wrapper entry just documents API.
// Actual echo used by int_wrapper_tcp is inlined there awaiting wrap leaf futures.

use io

func cmp_dyn_eq(got, want) {
    if got == want {
        return io.Ok
    }
    return io.OtherParse
}
