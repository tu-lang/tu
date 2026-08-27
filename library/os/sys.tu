//implement by asm
fn _getpid()
fn _fork()
fn _wait4()

// Windows-host process spawn thunks (kernel32); -ENOSYS stubs on unix.
// si/pi are caller-allocated STARTUPINFOA / PROCESS_INFORMATION buffers.
// Windows-host process spawn thunks (kernel32); -ENOSYS stubs on unix.
// si/pi are caller-allocated STARTUPINFOA / PROCESS_INFORMATION buffers.
fn win_create_process(cmd<i8*>, si<i8*>, pi<i8*>)
fn win_wait_object(h<u64>)
fn win_exit_code(h<u64>, out<i32*>)
fn win_close_handle(h<u64>)
fn win_find_first(pattern<i8*>)
fn win_find_next(h<u64>)
fn win_find_close(h<u64>)
fn win_find_name()
fn win_getcwd(buf<i8*>, n<i32>)
fn win_exe_path(buf<i8*>, n<i32>)
fn win_command_line_w()
fn win_cl_to_argv(cmdline_w<u64>, argc_out<i32*>)
fn win_local_free(p<u64>)
fn win_wchar_utf8(wstr<u64>, dst<i8*>, n<i32>)

//user space
export func getpid() {
	return int(_getpid())
}
export func fork(){
	return int(_fork())
}
