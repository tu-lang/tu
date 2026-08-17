.text
.global os__getpid  
os__getpid:
	mov    $39,%rax
	syscall
	retq   
.global os__fork
os__fork:
	mov $57 , %rax
	syscall
	retq
.global os__wait4
os__wait4:
	mov $61 , %rax
	syscall
	retq
# Windows-host process thunks: -ENOSYS stubs on linux (never called; the
# toolchain gates them behind runtime.host_os() == windows).
.global os_win_create_process
os_win_create_process:
	mov $-38, %rax
	retq
.global os_win_wait_object
os_win_wait_object:
	mov $-38, %rax
	retq
.global os_win_exit_code
os_win_exit_code:
	mov $-38, %rax
	retq
.global os_win_close_handle
os_win_close_handle:
	mov $-38, %rax
	retq


.global os_win_find_first
os_win_find_first:
	mov $-38, %rax
	retq
.global os_win_find_next
os_win_find_next:
	mov $-38, %rax
	retq
.global os_win_find_close
os_win_find_close:
	mov $-38, %rax
	retq
.global os_win_find_name
os_win_find_name:
	mov $-38, %rax
	retq
