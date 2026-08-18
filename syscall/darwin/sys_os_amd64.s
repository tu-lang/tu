# Darwin os package syscalls.
.text
.global os__getpid
os__getpid:
	mov $0x2000014, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne os_errno_neg
	retq

.global os__fork
os__fork:
	# Same Darwin SYS_fork ABI as std_fork (%edx distinguishes parent/child).
	mov $0x2000002, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne os_errno_neg
	mov %edx, %ecx
	cmp $0, %ecx
	je os_fork_parent
	xor %rax, %rax
os_fork_parent:
	retq

.global os__wait4
os__wait4:
	# Tu _wait4() has no args — wait for any child like a bare wait(2).
	mov $-1, %edi
	xor %esi, %esi
	xor %edx, %edx
	xor %r10, %r10
	mov $0x2000007, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne os_errno_neg
	retq

os_errno_neg:
	mov %rax, %rdi
	xor %rax, %rax
	sub %rdi, %rax
	retq

# Windows-host process thunks: -ENOSYS stubs on darwin (never called; the
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
.global os_win_getcwd
os_win_getcwd:
	mov $-38, %rax
	retq
