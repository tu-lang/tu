# Darwin platform overlays (installed by `make install-darwin`, not used on Linux).

| Source | Installed as | Role |
|--------|----------------|------|
| `runtime_os.tu` | `copkg/runtime/darwin.tu` | mmap, futex→ulock (asm in `syscall/darwin/`) |
| `os_signal.tu` | `copkg/os/signal.tu` | BSD signal numbers |
| `netio_platform.tu` | `copkg/netio/sys/platform.tu` | Sync connect finish + kqueue accept prep |

Linux keeps in-tree defaults: `runtime/linux.tu`, `library/os/signal.tu`,
`packages/netio/sys/platform.tu` (no-op hooks).

Public netio/tcp paths call `platform_*` hooks only; Darwin behavior is swapped
at install time, same pattern as kqueue over epoll.
