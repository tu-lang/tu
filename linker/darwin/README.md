# linker/darwin

Mach-O executable backend for `--target=darwin`.

## Role

- Input: Mach-O MH_OBJECT `.o` from `asmer/darwin`
- Output: Mach-O MH_EXECUTE

Fixed load base `0x100000000`, page-aligned segments, allowlisted libSystem imports via GOT + stub + `LC_DYLD_INFO_ONLY`.

Symbol names live in a `NameTab` (Mach-O strtab shape: leading NUL + `name\0`) with open-addressing intern. `ImageSym` / `ObjRel` / `ImportSlot` hold `i32 name_off` only (`n_strx`); defined lookup is `OffMap` on that off. The same pool is written as `LC_SYMTAB` strtab. No class strings on the link hot path.

## Stubs

| File | Purpose |
|------|---------|
| `stub_entry.s` | `_main` → `main_init.0` + `main_main`（源在 `platform/darwin/`，embed 随 stdroot） |

| `stub_runtime.s` | Minimal fillers for `-nostd` |

Install path: `/usr/local/lib/costub-darwin/` (override with `CO_DARWIN_LIB`).

## Cases

```bash
bash linker/darwin/cases/check_execute.sh
bash linker/darwin/cases/check_dyld_import.sh
bash linker/darwin/cases/check_pclntab.sh
```

Scripts skip (exit 0) when `uname` is not Darwin.

## Non-goals

- Host `ld` / `clang` fallback
- PIE + chained fixups
- Arbitrary dylibs beyond the libSystem allowlist
