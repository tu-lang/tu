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

// Owned cstr bits for argv/envp (string_to_bits copies into a GC buffer so
// temporary String args remain valid after Command::arg returns).
fn cstr_bits(s<string.String>) u64 {
    return string.string_to_bits(s)
}

// Start a command builder for `program`. Stdio defaults to inherit.
const Command::new(program<string.String>) Command {
    c<Command> = new Command
    c.program      = program
    c.argv[0]      = cstr_bits(program)
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
        this.argv[this.argc] = cstr_bits(s)
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
        this.envp[this.envc] = cstr_bits(kv)
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
    _fds<i32:2> = null
    fp<i32*> = &_fds
    r<i32> = std.pipe2(fp, std.O_CLOEXEC)
    if r < 0 return io.Other, -1, -1
    rfd<i32> = fp[0]
    wfd<i32> = fp[1]
    return io.Ok, rfd, wfd
}

// Spawn the child. On success returns (io.Ok, Child) with piped stdio halves
// populated for STDIO_PIPE fds. On fork/pipe failure returns (err, null) after
// closing any pipes already opened.
Command::spawn() i32, Child {
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

    // Mother: Command::current_dir → chdir(2) in the child. V1: no sys.chdir
    // in library/sys yet; reject before fork rather than call a missing symbol.
    if this.has_cwd == 1 return io.Unsupported, null

    // Resolve path/argv/envp pointers in the parent before fork. argv slots
    // already hold owned cstr copies from string_to_bits (mother owns OsString).
    prog_bits<u64> = this.argv[0]
    prog_p<i8*> = string.cstr_from_bits(prog_bits)
    argv_bytes<i32> = (this.argc + 1) * 8
    argv_buf<i8*> = new argv_bytes
    argv_slots<u64*> = argv_buf
    ai<i32> = 0
    while ai < this.argc {
        argv_slots[ai] = this.argv[ai]
        ai += 1
    }
    argv_slots[this.argc] = 0

    env_buf<i8*> = null
    if this.envc > 0 {
        this.envp[this.envc] = 0
        env_bytes<i32> = (this.envc + 1) * 8
        env_buf = new env_bytes
        env_slots<u64*> = env_buf
        ei<i32> = 0
        while ei < this.envc {
            env_slots[ei] = this.envp[ei]
            ei += 1
        }
        env_slots[this.envc] = 0
    }

    pid<i64> = std.fork()
    if pid == 0 {
        // Child: rewire std fds to the pipe ends, then exec (no GC/string).
        // dup2's newfd must be an i32 local — integer literals have been observed
        // to arrive corrupted in the 2nd arg (strace: dup2(6, 1744877232)).
        fd0<i32> = 0
        fd1<i32> = 1
        fd2<i32> = 2
        if in_r >= 0 {
            std.dup2(in_r, fd0)
            sys.close(in_r)
            sys.close(in_w)
        }
        if out_w >= 0 {
            std.dup2(out_w, fd1)
            sys.close(out_r)
            sys.close(out_w)
        }
        if err_w >= 0 {
            std.dup2(err_w, fd2)
            sys.close(err_r)
            sys.close(err_w)
        }
        if env_buf != null {
            std.execve(prog_p, argv_buf, env_buf)
        } else {
            std.execve(prog_p, argv_buf, runtime.ori_envp)
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
    pid_i<i32> = 0
    pid_i = pid
    child.pid    = pid_i
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

// Captured output of a finished command (tokio::process::Output).
mem Output {
    ExitStatus* status
    io.Buf*     stdout
    io.Buf*     stderr
}

// Leaf: spawn + drain pipes + wait (V1 inline). Mother: Command::output Future.
mem OutputFut: async {
    Command* cmd
}

OutputFut::poll(ctx) {
    c<Command> = this.cmd
    c.stdout_kind = STDIO_PIPE
    c.stderr_kind = STDIO_PIPE
    serr<i32>, child<Child> = c.spawn()
    if serr != io.Ok return runtime.PollReady, serr, null
    oerr<i32>, obuf<io.Buf> = read_all_fd(child.stdout.fd)
    if oerr != io.Ok return runtime.PollReady, oerr, null
    child.stdout.close()

    eerr<i32>, ebuf<io.Buf> = read_all_fd(child.stderr.fd)
    if eerr != io.Ok return runtime.PollReady, eerr, null
    child.stderr.close()

    werr<i32>, es<ExitStatus> = child.wait_sync()
    if werr != io.Ok return runtime.PollReady, werr, null

    out<Output> = new Output {
        status: es,
        stdout: obuf,
        stderr: ebuf
    }
    return runtime.PollReady, io.Ok, out
}

// Mother: Command::output — return OutputFut leaf (tcp connect / fs_read pattern).
Command::output() OutputFut {
    return new OutputFut { cmd: this }
}

// Leaf: spawn + wait (mother: Command::status).
mem StatusFut: async {
    Command* cmd
}

StatusFut::poll(ctx) {
    c<Command> = this.cmd
    serr<i32>, child<Child> = c.spawn()
    if serr != io.Ok return runtime.PollReady, serr, null
    werr<i32>, es<ExitStatus> = child.wait_sync()
    return runtime.PollReady, werr, es
}

Command::status() StatusFut {
    return new StatusFut { cmd: this }
}
