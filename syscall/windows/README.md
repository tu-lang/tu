# syscall/windows

Windows kernel32 / Winsock thunks for `--target=windows`. Tu internal calls stay SysV;
each export rearranges into Win64 (`rcx/rdx/r8/r9` + 32-byte shadow) before the API.

Mirrors `syscall/darwin/`. Install: `install-windows.cmd` or `make install-windows` →
`lib/coasm-windows`.

## Networking (V1)

Full BSD surface used by `library/sys` / netio: `socket` (strips `SOCK_NONBLOCK` /
`SOCK_CLOEXEC`, maps `AF_INET6` 10→23), `bind` / `connect` / `listen` / `accept4`,
`send` / `sendto` / `recv` / `recvfrom`, `shutdown`, `setsockopt` / `getsockopt`,
`fcntl(O_NONBLOCK)` via `ioctlsocket`, sock-aware `read`/`write`/`close`.

Linux `SOL_SOCKET` / `SO_*` / errno numbers are translated at the boundary.
Nonblocking `connect` maps `WSAEWOULDBLOCK`/`WSAEINPROGRESS` → `-EINPROGRESS` (-115).
`send`/`recv`/`recvfrom`/`sendto` treat Winsock `SOCKET_ERROR` via **32-bit**
`cmp $-1, %eax` (high half of `rax` is zero on error).

Reactor: software `sys_epoll_*` over `WSAPoll` (same `packages/netio/sys/epoll.tu`
path as Linux). `sys_eventfd` is a UDP loopback waker. True overlapped IOCP
(AcceptEx / ConnectEx / WSARecv) is a later slice.

## FS / threads

`sys_mkdir` / `sys_rmdir` / `sys_unlink` / `sys_openat(AT_FDCWD)` map to Win32
file APIs. Process start creates drive `\tmp` for Linux-style `/tmp/...` paths.
Threads: `CreateThread` + `WaitOnAddress` / `WakeByAddressAll`.

## Host gate

`co/windows/run_tests.ps1` (default TimeoutSec=120). Formal socket/FS coverage:
`tests/native/sys_fs_path.tu`.
