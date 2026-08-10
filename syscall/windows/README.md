# syscall/windows

Windows kernel32 thunks for `--target=windows`. Tu internal calls stay SysV; each export rearranges into Win64 (`rcx/rdx/r8/r9` + 32-byte shadow) before `WriteFile` / `VirtualAlloc` / `CreateThread` / `WaitOnAddress`.

Mirrors `syscall/darwin/`. Install: `install-windows.cmd` or `make install-windows` → `lib/coasm-windows`.

Net `sys_*` return `-ENOSYS` until IOCP lands. `fmt.println` + runtime GC/threads use std + runtime asm only.
