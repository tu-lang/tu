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

//user space
func getpid() {
	return int(_getpid())
}
func fork(){
	return int(_fork())
}
