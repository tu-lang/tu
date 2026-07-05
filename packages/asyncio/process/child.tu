// Spawned child handle + exit status (tokio::process::Child / ExitStatus).
//
// Design note (task 17.4/17.5): the spec pairs Child with a
// sync.oneshot.Receiver fed by a reaper task. Since the reactor-driven
// reaper (reap.tu / pidfd.tu) is not yet wired into a running IO driver,
// Child::wait reaps synchronously via waitpid here (V1); the oneshot exit
// channel lands once the reaper runs on the driver. `class Child` becomes a
// `mem` per library-static-only.

use runtime
use io
use std
use sys
use os

// A process exit outcome. Exactly one of code / signum is meaningful:
// a normal exit sets code (signum 0); a signal death sets signum (code -1).
mem ExitStatus {
    i32 code    // exit code for a normal exit, else -1
    i32 signum  // terminating signal, else 0
}

// Decode a waitpid status word into an ExitStatus (WIFEXITED / WIFSIGNALED).
// status & 0x7f == 0 means normal exit; low 7 bits otherwise are the signal
// (0x7f marks a stop, which is not a termination and is reported as signum 0).
fn exit_status_from_wait(status<i32>) ExitStatus {
    es<ExitStatus> = new ExitStatus
    ts<i32> = status & 127
    if ts == 0 {
        es.code   = (status >> 8) & 255
        es.signum = 0
    } else if ts == 127 {
        es.code   = -1
        es.signum = 0
    } else {
        es.code   = -1
        es.signum = ts
    }
    return es
}

// True for a clean exit with code 0.
ExitStatus::success() bool {
    if this.code == 0 && this.signum == 0 return true
    return false
}

// Exit code (-1 when the process was signalled).
ExitStatus::code() i32 {
    return this.code
}

// Terminating signal number (0 when the process exited normally).
ExitStatus::signal() i32 {
    return this.signum
}

// A spawned child. Piped stdio halves are non-null only for STDIO_PIPE kinds.
// `reaped` flips 0 -> 1 once the exit status has been collected and cached.
mem Child {
    i32          pid
    ChildStdin*  stdin
    ChildStdout* stdout
    ChildStderr* stderr
    i32          reaped
    ExitStatus*  status
}

// The child's process id.
Child::id() u32 {
    return this.pid.(u32)
}

// Send SIGKILL without waiting. Returns io.NotFound if the child was already
// reaped, else the kill(2) result.
Child::start_kill() i32 {
    if this.reaped == 1 return io.NotFound
    err<i32>, _ = sys.cvt(sys_kill(this.pid, os.SIGKILL))
    return err
}

// Block until the child exits and return its ExitStatus. Cached after the
// first successful reap. V1: synchronous waitpid (blocking) on the calling
// task; the reactor-driven reaper path is deferred.
async Child::wait() i32, ExitStatus {
    if this.reaped == 1 return io.Ok, this.status
    status<i32> = 0
    r<i32> = std.waitpid(this.pid, (&status).(u64), 0)
    if r < 0 return io.Other, null
    es<ExitStatus> = exit_status_from_wait(status)
    this.status = es
    this.reaped = 1
    return io.Ok, es
}

// Non-blocking reap. Returns (io.Ok, status) once exited, (io.WouldBlock, null)
// while still running, or (io.Other, null) on a waitpid error.
Child::try_wait() i32, ExitStatus {
    if this.reaped == 1 return io.Ok, this.status
    status<i32> = 0
    r<i32> = std.waitpid(this.pid, (&status).(u64), std.WNOHANG)
    if r < 0 return io.Other, null
    if r == 0 return io.WouldBlock, null
    es<ExitStatus> = exit_status_from_wait(status)
    this.status = es
    this.reaped = 1
    return io.Ok, es
}

// SIGKILL the child and reap it. Returns io.Ok once collected.
async Child::kill() i32 {
    kerr<i32> = this.start_kill()
    if kerr != io.Ok return kerr
    werr<i32>, _ = this.wait().await
    return werr
}
