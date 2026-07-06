// tokio::signal::ctrl_c — resolve on the first SIGINT.
//
// Equivalent to subscribing via signal(SignalKind_interrupt()) and awaiting a
// single recv(); the SignalStream is dropped afterwards.

use io

// Complete once the process receives its first SIGINT after this call.
// Returns io.Ok on delivery, or the register error when no signal driver is
// available (e.g. RuntimeShutdown).
async ctrl_c() i32 {
    serr<i32>, stream<SignalStream> = signal(SignalKind_interrupt()).await
    if serr != io.Ok return serr
    return stream.recv().await
}
