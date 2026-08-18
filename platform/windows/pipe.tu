# Windows pipe2 via CreatePipe (RFC-107 P1).
# Installed as runtime/pipe.tu → runtime_win_pipe2_tu.
# Handles live in win_fds as files (ReadFile/WriteFile), not SOCKETs.
# Default CreatePipe handles are non-inheritable (CLOEXEC). Without O_CLOEXEC,
# SetHandleInformation enables HANDLE_FLAG_INHERIT. O_NONBLOCK tries PIPE_NOWAIT
# (anonymous pipes may ignore it on some hosts).

WIN_PIPE_O_NONBLOCK<i64> = 0x800
WIN_PIPE_O_CLOEXEC<i64> = 0x80000
WIN_HANDLE_FLAG_INHERIT<u32> = 1

# No-body: SysV → Win64. Implemented in syscall/windows.
fn win_api_create_pipe(pread<u64>, pwrite<u64>) (i32)
fn win_api_set_handle_info(h<u64>, mask<u32>, flags<u32>) (i32)
fn win_api_pipe_nowait(h<u64>) (i32)
fn win_api_close_handle(h<u64>) (i32)

# Create a pipe, stash both HANDLEs in the fd table, fill fds[2].
# Returns 0 or -errno (EFAULT=-14, EMFILE=-24, generic -1 on CreatePipe fail).
fn win_pipe2_tu(fds<u64>, flags<i64>, table<u64*>) i64 {
	if fds == 0.(u64) {
		return -14.(i64)
	}
	hp<u64*> = malloc(16.(u64), 1.(i8), 1.(i8))
	base<u64> = hp.(u64)
	ok<i32> = win_api_create_pipe(base, base + 8.(u64))
	rh<u64> = hp[0]
	wh<u64> = hp[1]
	if ok == 0 {
		return -1.(i64)
	}
	if rh == 0.(u64) {
		return -1.(i64)
	}
	if wh == 0.(u64) {
		win_api_close_handle(rh)
		return -1.(i64)
	}
	rfd<i32> = win_fd_alloc_tu(rh, table)
	if rfd < 0 {
		win_api_close_handle(rh)
		win_api_close_handle(wh)
		return -24.(i64)
	}
	wfd<i32> = win_fd_alloc_tu(wh, table)
	if wfd < 0 {
		win_fd_slot_clear_tu(rfd.(i64), table)
		win_api_close_handle(rh)
		win_api_close_handle(wh)
		return -24.(i64)
	}
	if (flags & WIN_PIPE_O_CLOEXEC) == 0.(i64) {
		win_api_set_handle_info(rh, WIN_HANDLE_FLAG_INHERIT, WIN_HANDLE_FLAG_INHERIT)
		win_api_set_handle_info(wh, WIN_HANDLE_FLAG_INHERIT, WIN_HANDLE_FLAG_INHERIT)
	}
	if (flags & WIN_PIPE_O_NONBLOCK) != 0.(i64) {
		win_api_pipe_nowait(rh)
		win_api_pipe_nowait(wh)
	}
	out<i32*> = fds
	out[0] = rfd
	out[1] = wfd
	return 0.(i64)
}
