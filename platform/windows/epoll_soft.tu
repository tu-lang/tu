# Software epoll over WSAPoll (RFC-107 P1).
# Tables stay in asm .data; this file owns create/ctl/wait policy.
# Win64 APIs (WSAPoll/accept/recv/Sleep) are no-body fns → SysV trampolines.

WIN_EP_MAX_SETS<i32> = 16
WIN_EP_CAP<i32> = 128

EPOLL_CTL_ADD<i32> = 1
EPOLL_CTL_DEL<i32> = 2
EPOLL_CTL_MOD<i32> = 3

EPOLLIN<i32> = 0x1
EPOLLOUT<i32> = 0x4
EPOLLERR<i32> = 0x8
EPOLLHUP<i32> = 0x10

POLL_RD<i32> = 0x300
POLL_WR<i32> = 0x10
POLL_ERR<i32> = 0x1
POLL_HUP<i32> = 0x2
POLL_RDNORM<i32> = 0x100
MSG_PEEK<i32> = 2

# No-body: SysV rdi/rsi/rdx/rcx → Win64. Implemented in syscall/windows.
fn win_api_wsapoll(fds<u64>, nfds<i32>, timeout<i32>) (i32)
fn win_api_accept(sock<u64>) (i64)
fn win_api_recv(sock<u64>, buf<u64>, len<i32>, flags<i32>) (i32)
fn win_api_sleep(ms<i32>) (i32)
fn win_api_wsafail() (i64)

fn ep_slot(ep<i32>, j<i32>) i32 {
	s<i32> = ep << 7
	return s + j
}

fn ep_idx_of(epfd<i64>, ep_map<i8*>) i32 {
	idx<i32> = win_ep_get_fd_tu(epfd, ep_map)
	if idx == WIN_EP_NONE {
		return -1
	}
	if idx >= WIN_EP_MAX_SETS {
		return -1
	}
	return idx
}

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

fn find_in_set(ep<i32>, tufd<i32>, n_table<i32*>, fds<i32*>) i32 {
	nn<i32> = n_table[ep]
	j<i32> = 0
	while j < nn {
		sl<i32> = ep_slot(ep, j)
		if fds[sl] == tufd {
			return j
		}
		j = j + 1
	}
	return -1
}

# Packed epoll_event: u32 events at 0, u64 token at +4.
fn write_ev_tok(sl<i32>, event<u64>, evs<i32*>, toks<u64*>) {
	fp<i32*> = event
	ev<i32> = *fp
	evs[sl] = ev
	tokp<u64> = event + 4
	tp<u64*> = tokp
	tk<u64> = *tp
	toks[sl] = tk
}

# Linux epoll_ctl ops: ADD=1 DEL=2 MOD=3. Returns 0 or -errno.
fn win_epoll_ctl_tu(epfd<i64>, op<i64>, fd<i64>, event<u64>, used<i8*>, n_table<i32*>, fds<i32*>, evs<i32*>, toks<u64*>, ep_map<i8*>) i64 {
	ep<i32> = ep_idx_of(epfd, ep_map)
	if ep < 0 {
		return -9.(i64)
	}
	if used[ep] == 0.(i8) {
		return -9.(i64)
	}
	tufd<i32> = fd.(i32)
	if op == EPOLL_CTL_DEL.(i64) {
		hit<i32> = find_in_set(ep, tufd, n_table, fds)
		if hit < 0 {
			return 0.(i64)
		}
		nn<i32> = n_table[ep]
		last<i32> = nn - 1
		dst<i32> = ep_slot(ep, hit)
		src<i32> = ep_slot(ep, last)
		fds[dst] = fds[src]
		evs[dst] = evs[src]
		toks[dst] = toks[src]
		n_table[ep] = last
		return 0.(i64)
	}
	if op == EPOLL_CTL_ADD.(i64) {
		hit<i32> = find_in_set(ep, tufd, n_table, fds)
		if hit >= 0 {
			write_ev_tok(ep_slot(ep, hit), event, evs, toks)
			return 0.(i64)
		}
		nn<i32> = n_table[ep]
		if nn >= WIN_EP_CAP {
			return -24.(i64)
		}
		sl<i32> = ep_slot(ep, nn)
		fds[sl] = tufd
		write_ev_tok(sl, event, evs, toks)
		n_table[ep] = nn + 1
		return 0.(i64)
	}
	if op == EPOLL_CTL_MOD.(i64) {
		hit<i32> = find_in_set(ep, tufd, n_table, fds)
		if hit < 0 {
			return -2.(i64)
		}
		write_ev_tok(ep_slot(ep, hit), event, evs, toks)
		return 0.(i64)
	}
	return -22.(i64)
}

fn epoll_to_poll(ev<i32>) i32 {
	out<i32> = 0
	if (ev & EPOLLIN) != 0 {
		out = out + POLL_RDNORM
	}
	if (ev & EPOLLOUT) != 0 {
		out = out + POLL_WR
	}
	return out
}

fn poll_to_epoll(rev<i32>) i32 {
	out<i32> = 0
	if (rev & POLL_RD) != 0 {
		out = out + EPOLLIN
	}
	if (rev & POLL_WR) != 0 {
		out = out + EPOLLOUT
	}
	if (rev & POLL_ERR) != 0 {
		out = out + EPOLLERR
	}
	if (rev & POLL_HUP) != 0 {
		out = out + EPOLLHUP
	}
	return out
}

# 12-byte packed epoll_event: flags u32 at 0, token u64 at +4.
fn write_packed(out_bits<u64>, flags<i32>, tok<u64>) {
	fp<i32*> = out_bits
	*fp = flags
	tokp<u64> = out_bits + 4
	tp<u64*> = tokp
	*tp = tok
}

# Probe a listen fd: reuse stash, else accept(NULL,NULL) and stash.
fn listen_ready(tufd<i32>, listen_tab<i8*>, stash<u64*>, fd_table<u64*>) i32 {
	if tufd < 0 {
		return 0
	}
	if tufd >= 256 {
		return 0
	}
	if listen_tab[tufd] == 0.(i8) {
		return 0
	}
	if stash[tufd] != 0.(u64) {
		return 1
	}
	sock<u64> = win_fd_get_tu(tufd.(i64), fd_table)
	if sock == 0.(u64) {
		return 0
	}
	acc<i64> = win_api_accept(sock)
	if acc == -1.(i64) {
		return 0
	}
	stash[tufd] = acc.(u64)
	return 1
}

fn peek_ready(tufd<i32>, sock0<u64>, fd_table<u64*>) i32 {
	sock<u64> = sock0
	if sock == 0.(u64) {
		sock = win_fd_get_tu(tufd.(i64), fd_table)
	}
	if sock == 0.(u64) {
		return 0
	}
	b<i8> = 0
	bp<i8*> = &b
	n<i32> = win_api_recv(sock, bp.(u64), 1, MSG_PEEK)
	if n > 0 {
		return 1
	}
	return 0
}

# WSAPoll + listen/MSG_PEEK probes. Matches prior asm wait semantics.
fn win_epoll_wait_tu(epfd<i64>, events_out<u64>, maxevents<i64>, timeout<i64>, used<i8*>, n_table<i32*>, fds<i32*>, evs<i32*>, toks<u64*>, ep_map<i8*>, fd_table<u64*>, listen_tab<i8*>, stash<u64*>) i64 {
	ep<i32> = ep_idx_of(epfd, ep_map)
	if ep < 0 {
		return -9.(i64)
	}
	if used[ep] == 0.(i8) {
		return -9.(i64)
	}
	nn<i32> = n_table[ep]
	if nn <= 0 {
		ms<i32> = timeout.(i32)
		if timeout == -1.(i64) {
			ms = -1
		}
		win_api_sleep(ms)
		return 0.(i64)
	}
	pf<i8*> = malloc(2048.(u64), 1.(u8), 1.(u8))
	j<i32> = 0
	while j < nn {
		sl<i32> = ep_slot(ep, j)
		tufd<i32> = fds[sl]
		sock<u64> = win_fd_get_tu(tufd.(i64), fd_table)
		off<i32> = j << 4
		row<i8*> = pf + off
		sp<u64*> = row
		*sp = sock
		ev16<i32> = epoll_to_poll(evs[sl])
		q1<i8*> = row + 8
		qp<u64*> = q1
		*qp = ev16.(u64)
		j = j + 1
	}
	to<i32> = timeout.(i32)
	j = 0
	while j < nn {
		sl<i32> = ep_slot(ep, j)
		if (evs[sl] & EPOLLIN) != 0 {
			if listen_ready(fds[sl], listen_tab, stash, fd_table) != 0 {
				to = 0
				break
			}
		}
		j = j + 1
	}
	if timeout == -1.(i64) && to != 0 {
		to = 1
	}
	pr<i32> = win_api_wsapoll(pf.(u64), nn, to)
	if pr == -1 {
		return win_api_wsafail()
	}
	outn<i32> = 0
	maxe<i32> = maxevents.(i32)
	j = 0
	while j < nn {
		if outn >= maxe {
			break
		}
		off<i32> = j << 4
		q1<i8*> = pf + off + 8
		qp<u64*> = q1
		q<u64> = *qp
		sh<u64> = q >> 16
		rev<i32> = (sh & 65535.(u64)).(i32)
		sl<i32> = ep_slot(ep, j)
		tufd<i32> = fds[sl]
		if rev == 0 {
			if (evs[sl] & EPOLLIN) != 0 {
				if listen_ready(tufd, listen_tab, stash, fd_table) != 0 {
					rev = POLL_RDNORM
				} else {
					row<i8*> = pf + off
					skp<u64*> = row
					sk<u64> = *skp
					if peek_ready(tufd, sk, fd_table) != 0 {
						rev = POLL_RDNORM
					}
				}
			}
		}
		if rev != 0 {
			fl<i32> = poll_to_epoll(rev)
			offo<u64> = outn.(u64) * 12.(u64)
			write_packed(events_out + offo, fl, toks[sl])
			outn = outn + 1
		}
		j = j + 1
	}
	return outn.(i64)
}
