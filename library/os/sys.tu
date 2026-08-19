//implement by asm
func _getpid()
func _fork()
func _wait4()

// Windows-host process spawn thunks (kernel32); -ENOSYS stubs on unix.
// si/pi are caller-allocated STARTUPINFOA / PROCESS_INFORMATION buffers.
// Windows-host process spawn thunks (kernel32); -ENOSYS stubs on unix.
// si/pi are caller-allocated STARTUPINFOA / PROCESS_INFORMATION buffers.
func win_create_process(cmd<i8*>, si<i8*>, pi<i8*>)
func win_wait_object(h<u64>)
func win_exit_code(h<u64>, out<i32*>)
func win_close_handle(h<u64>)
func win_find_first(pattern<i8*>)
func win_find_next(h<u64>)
func win_find_close(h<u64>)
func win_find_name()
func win_getcwd(buf<i8*>, n<i32>)
func win_exe_path(buf<i8*>, n<i32>)
func win_command_line_w()
func win_cl_to_argv(cmdline_w<u64>, argc_out<i32*>)
func win_local_free(p<u64>)
func win_wchar_utf8(wstr<u64>, dst<i8*>, n<i32>)

//user space
func getpid() {
	return int(_getpid())
}
func fork(){
	return int(_fork())
}
