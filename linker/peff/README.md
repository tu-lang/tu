# linker/peff

PE executable backend for `--target=windows`.

Mirrors `linker/darwin/`: public dispatch lives in `tulang.tu` / `linker/main.tu`.
Directory name **peff** is the object/image format (same idea as `elf`).

## Role

- Input: COFF `.o` from `asmer/peff` only
- Output: PE `*.exe` written by this package
- User machine: a single `tu` binary. No `tuc`, no `tul`, no `link.exe`

## Implementation

| Piece | Where |
|-------|--------|
| COFF load | `object.tu` |
| Merge / relocs / PE write | `image.tu` |
| Win32 IAT + jmp stubs | `imports.tu` |
| pclntab | `pcln.tu` (expand + fill, same layout as ELF/Darwin) |
| nostd stubs | `platform/windows/stub_entry.s` / `stub_runtime.s`（embed；disk 装到 `copeff/`） |


ImageBase is `0x140000000`, `/FIXED`-style (no `.reloc`). Imports come from the syscall allowlist:

| DLL | Typical symbols |
|-----|-----------------|
| `kernel32.dll` | process / file / memory / console |
| `shell32.dll` | shell helpers |
| `ws2_32.dll` | Winsock |
| `api-ms-win-core-synch-l1-2-0.dll` | `WaitOnAddress` / `WakeByAddressAll` |

Stub search: `CO_PEFF_LIB` then `CO_WINDOWS_LIB` then prefix `lib/copeff`.
