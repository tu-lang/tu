// Process builder + launch (tokio::process::Command).
//
// Design note (task 17.6-17.8): `class Command` becomes a `mem` per
// library-static-only. argv / envp are fixed-capacity pointer arrays
// (MAX_ARGS entries incl. argv[0]); overflowing them is a V1 limitation.
// spawn uses fork + dup2 + execve directly (mirrors library/os/shell.tu);
// pidfd registration and the reactor-driven reaper are deferred, so wait
// reaps synchronously (see child.tu).

use runtime
use io
use std
use sys
use string

// Stdio disposition per fd. Matches the task's 0=Null / 1=Inherit / 2=Pipe.
STDIO_NULL<i32>    = 0
STDIO_INHERIT<i32> = 1
STDIO_PIPE<i32>    = 2

// Fixed argv / envp capacity (including the trailing NULL slot).
MAX_ARGS<i32> = 64
MAX_ENVS<i32> = 64

// execve failure exit code, matching the shell convention.
EXIT_EXEC_FAIL<i32> = 127

// A command to run. argv[0] is the program; envp is empty => inherit the
// parent environment. cwd applies only when has_cwd == 1.
mem Command {
    string.String program
    u64           argv[64]   // i8* pointers; argv[0]=program, NUL-terminated at spawn
    i32           argc
    u64           envp[64]   // i8* "KEY=VAL" pointers, NUL-terminated at spawn
    i32           envc
    i32           stdin_kind
    i32           stdout_kind
    i32           stderr_kind
    string.String cwd
    i32           has_cwd
    i32           kill_on_drop
}

// Start a command builder for `program`. Stdio defaults to inherit.
const Command::new(program<string.String>) Command {
    c<Command> = new Command
    c.program      = program
    c.argv[0]      = program.str().(u64)
    c.argc         = 1
    c.envc         = 0
    c.stdin_kind   = STDIO_INHERIT
    c.stdout_kind  = STDIO_INHERIT
    c.stderr_kind  = STDIO_INHERIT
    c.has_cwd      = 0
    c.kill_on_drop = 0
    return c
}

// Append one argument. Silently ignored once MAX_ARGS-1 args are present.
Command::arg(s<string.String>) Command {
    if this.argc < MAX_ARGS - 1 {
        this.argv[this.argc] = s.str().(u64)
        this.argc += 1
    }
    return this
}

// Add a "KEY=VAL" environment entry. Presence of any entry switches the child
// from inherited environment to this explicit set.
Command::env(k<string.String>, v<string.String>) Command {
    if this.envc < MAX_ENVS - 1 {
        kv<string.String> = k.dup()
        kv.catstr(*"=")
        kv.cat(v)
        this.envp[this.envc] = kv.str().(u64)
        this.envc += 1
    }
    return this
}

// Set the working directory for the child.
Command::current_dir(p<string.String>) Command {
    this.cwd     = p
    this.has_cwd = 1
    return this
}

// Configure stdin / stdout / stderr disposition (STDIO_NULL/INHERIT/PIPE).
Command::stdin(kind<i32>) Command {
    this.stdin_kind = kind
    return this
}
Command::stdout(kind<i32>) Command {
    this.stdout_kind = kind
    return this
}
Command::stderr(kind<i32>) Command {
    this.stderr_kind = kind
    return this
}

// Kill the child when the Child handle is dropped (advisory flag; honoured by
// the caller's drop path).
Command::kill_on_drop(yes<i32>) Command {
    this.kill_on_drop = yes
    return this
}

// Create a CLOEXEC pipe. Returns (io.Ok, read_fd, write_fd) or (err, -1, -1).
// CLOEXEC closes both ends across execve; the child keeps only the dup2'd
// std fds (dup2 clears CLOEXEC), so the raw ends never leak into the program.
fn make_pipe() i32, i32, i32 {
    fds<i32:2> = null
    r<i32> = std.pipe2(&fds, std.O_CLOEXEC)
    if r < 0 return io.Other, -1, -1
    return io.Ok, fds[0], fds[1]
}

// Spawn the child. On success returns (io.Ok, Child) with piped stdio halves
// populated for STDIO_PIPE fds. On fork/pipe failure returns (err, null) after
// closing any pipes already opened.
Command::spawn() (i32, Child) {
    in_r<i32>  = -1
    in_w<i32>  = -1
    out_r<i32> = -1
    out_w<i32> = -1
    err_r<i32> = -1
    err_w<i32> = -1

    if this.stdin_kind == STDIO_PIPE {
        e<i32>, r<i32>, w<i32> = make_pipe()
        if e != io.Ok return e, null
        in_r = r
        in_w = w
    }
    if this.stdout_kind == STDIO_PIPE {
        e<i32>, r<i32>, w<i32> = make_pipe()
        if e != io.Ok {
            close_fd(in_r)
            close_fd(in_w)
            return e, null
        }
        out_r = r
        out_w = w
    }
    if this.stderr_kind == STDIO_PIPE {
        e<i32>, r<i32>, w<i32> = make_pipe()
        if e != io.Ok {
            close_fd(in_r)
            close_fd(in_w)
            close_fd(out_r)
            close_fd(out_w)
            return e, null
        }
        err_r = r
        err_w = w
    }

    // NUL-terminate argv / envp for execve.
    this.argv[this.argc] = 0

    pid<i64> = std.fork()
    if pid == 0 {
        // Child: rewire std fds to the pipe ends, chdir, then exec.
        if this.stdin_kind  == STDIO_PIPE std.dup2(in_r, 0)
        if this.stdout_kind == STDIO_PIPE std.dup2(out_w, 1)
        if this.stderr_kind == STDIO_PIPE std.dup2(err_w, 2)
        if this.has_cwd == 1 sys.cvt(sys_chdir(this.cwd.str()))
        if this.envc > 0 {
            this.envp[this.envc] = 0
            std.execve(this.program.str(), (&this.argv).(i8*), (&this.envp).(i8*))
        } else {
            std.execve(this.program.str(), (&this.argv).(i8*), runtime.ori_envp)
        }
        std.die(EXIT_EXEC_FAIL.(i8))
    }
    if pid < 0 {
        close_fd(in_r)
        close_fd(in_w)
        close_fd(out_r)
        close_fd(out_w)
        close_fd(err_r)
        close_fd(err_w)
        return io.Other, null
    }

    // Parent: close the child ends, keep our side of each pipe.
    child<Child> = new Child
    child.pid    = pid.(i32)
    child.reaped = 0
    child.status = null
    child.stdin  = null
    child.stdout = null
    child.stderr = null

    if this.stdin_kind == STDIO_PIPE {
        close_fd(in_r)
        child.stdin = new ChildStdin { fd: in_w }
    }
    if this.stdout_kind == STDIO_PIPE {
        close_fd(out_w)
        child.stdout = new ChildStdout { fd: out_r }
    }
    if this.stderr_kind == STDIO_PIPE {
        close_fd(err_w)
        child.stderr = new ChildStderr { fd: err_r }
    }
    return io.Ok, child
}

// Spawn and wait for exit. Returns (io.Ok, ExitStatus) or (err, null).
async Command::status() i32, ExitStatus {
    serr<i32>, child<Child> = this.spawn()
    if serr != io.Ok return serr, null
    return child.wait().await
}

// Captured output of a finished command.
mem Output {
    ExitStatus* status
    io.Buf*     stdout
    io.Buf*     stderr
}

// Spawn with stdout+stderr piped, drain both, then wait. Returns
// (io.Ok, Output) or (err, null). Drains stdout fully before stderr, so a
// child that floods stderr while stdout is unread can deadlock (V1 caveat).
async Command::output() i32, Output {
    this.stdout_kind = STDIO_PIPE
    this.stderr_kind = STDIO_PIPE
    serr<i32>, child<Child> = this.spawn()
    if serr != io.Ok return serr, null

    oerr<i32>, obuf<io.Buf> = read_all_fd(child.stdout.fd)
    if oerr != io.Ok return oerr, null
    child.stdout.close()

    eerr<i32>, ebuf<io.Buf> = read_all_fd(child.stderr.fd)
    if eerr != io.Ok return eerr, null
    child.stderr.close()

    werr<i32>, es<ExitStatus> = child.wait().await
    if werr != io.Ok return werr, null

    return io.Ok, new Output { status: es, stdout: obuf, stderr: ebuf }
}
