# Windows fd / epoll-fd maps (RFC-107 P1).
# Tables stay in asm .data (win_fds / win_fd_sock / win_ep_fd_of) because
# win_init_stdio runs before GC; Tu owns policy via table-base pointer args.
# Asm trampolines: SysV %rdi/%rsi -> push stack args -> these symbols.

WIN_FD_MAX<i64> = 256
# Byte markers stored in i8 slots (0xFF / 0xFE as signed).
WIN_EP_NONE_B<i8> = -1
WIN_EP_READY_B<i8> = -2
WIN_EP_NONE<i32> = 255

# Return HANDLE/SOCKET bits for fd, or 0 if invalid/empty.
fn win_fd_get_tu(fd<i64>, table<u64*>) u64 {
	if fd < 0 {
		return 0.(u64)
	}
	if fd >= WIN_FD_MAX {
		return 0.(u64)
	}
	idx<i32> = fd.(i32)
	return table[idx]
}

# Store handle into win_fds[fd].
fn win_fd_set_tu(fd<i64>, handle<u64>, table<u64*>) {
	if fd < 0 {
		return
	}
	if fd >= WIN_FD_MAX {
		return
	}
	idx<i32> = fd.(i32)
	table[idx] = handle
}

# Clear win_fds[fd] slot.
fn win_fd_slot_clear_tu(fd<i64>, table<u64*>) {
	if fd < 0 {
		return
	}
	if fd >= WIN_FD_MAX {
		return
	}
	idx<i32> = fd.(i32)
	table[idx] = 0.(u64)
}

# Allocate lowest free fd >= 3; store handle; return fd or -1.
fn win_fd_alloc_tu(handle<u64>, table<u64*>) i32 {
	i<i32> = 3
	while i < 256 {
		if table[i] == 0.(u64) {
			table[i] = handle
			return i
		}
		i = i + 1
	}
	return -1
}

# Mark fd as Winsock SOCKET (sock_table is i8[256]).
fn win_fd_mark_sock_tu(fd<i64>, sock_table<i8*>) {
	if fd < 0 {
		return
	}
	if fd >= WIN_FD_MAX {
		return
	}
	idx<i32> = fd.(i32)
	sock_table[idx] = 1.(i8)
}

fn win_fd_clear_sock_tu(fd<i64>, sock_table<i8*>) {
	if fd < 0 {
		return
	}
	if fd >= WIN_FD_MAX {
		return
	}
	idx<i32> = fd.(i32)
	sock_table[idx] = 0.(i8)
}

# Return 1 if sock mark set.
fn win_fd_is_sock_tu(fd<i64>, sock_table<i8*>) i32 {
	if fd < 0 {
		return 0
	}
	if fd >= WIN_FD_MAX {
		return 0
	}
	idx<i32> = fd.(i32)
	v<i8> = sock_table[idx]
	return v.(i32)
}

# Ensure ep_map[255]==0xFE; else fill all slots with 0xFF then set sentinel.
fn win_ep_map_ensure_tu(ep_table<i8*>) {
	mark<i8> = ep_table[255]
	if mark == WIN_EP_READY_B {
		return
	}
	i<i32> = 0
	while i < 256 {
		ep_table[i] = WIN_EP_NONE_B
		i = i + 1
	}
	ep_table[255] = WIN_EP_READY_B
}

# Store ep_idx+1 at ep_map[fd] (0 means not-epoll).
fn win_ep_set_fd_tu(fd<i64>, ep_idx<i64>, ep_table<i8*>) {
	win_ep_map_ensure_tu(ep_table)
	if fd < 0 {
		return
	}
	if fd >= WIN_FD_MAX {
		return
	}
	idx<i32> = fd.(i32)
	v<i64> = ep_idx + 1
	ep_table[idx] = v.(i8)
}

# Return ep_idx or 255 if not an epoll fd.
fn win_ep_get_fd_tu(fd<i64>, ep_table<i8*>) i32 {
	win_ep_map_ensure_tu(ep_table)
	if fd < 0 {
		return WIN_EP_NONE
	}
	if fd >= WIN_FD_MAX {
		return WIN_EP_NONE
	}
	idx<i32> = fd.(i32)
	raw<i8> = ep_table[idx]
	if raw == 0.(i8) {
		return WIN_EP_NONE
	}
	ub<u8> = raw.(u8)
	ri<i32> = ub.(i32)
	return ri - 1
}

fn win_ep_clear_fd_tu(fd<i64>, ep_table<i8*>) {
	win_ep_map_ensure_tu(ep_table)
	if fd < 0 {
		return
	}
	if fd >= WIN_FD_MAX {
		return
	}
	idx<i32> = fd.(i32)
	ep_table[idx] = 0.(i8)
}
