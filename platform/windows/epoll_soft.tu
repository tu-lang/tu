# Software epoll create (RFC-107 P1). Tables stay in asm .data.
# ctl/wait remain in syscall asm until the next slice.

WIN_EP_MAX_SETS<i32> = 16

# Allocate an epoll set: mark used[i], clear n[i], alloc fd, map fd→idx.
# Returns tu fd (>=0) or negative errno.
fn win_epoll_create1_tu(used<i8*>, n_table<i32*>, fds_table<u64*>, ep_map<i8*>) i64 {
	i<i32> = 0
	while i < WIN_EP_MAX_SETS {
		if used[i] == 0.(i8) {
			used[i] = 1.(i8)
			n_table[i] = 0
			fd<i32> = win_fd_alloc_tu(1.(u64), fds_table)
			if fd < 0 {
				used[i] = 0.(i8)
				return -24.(i64)
			}
			win_ep_set_fd_tu(fd.(i64), i.(i64), ep_map)
			return fd.(i64)
		}
		i = i + 1
	}
	return -24.(i64)
}
