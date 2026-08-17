# linker/peff

PE executable backend for `--target=windows`.

Mirrors `linker/darwin/`: public dispatch lives in `tulang.tu` / `linker/main.tu`;
link strategy and nostd stubs live here. Directory name **peff** aligns with mother `co/linker/peff`.

## Role

- Input: COFF `.o` from `asmer/peff` only
- Output: PE `*.exe`

## Phase status

| Phase | Implementation |
|-------|----------------|
| W1 | Host `link.exe` / `lld-link` + `stub_entry.s` / `stub_runtime.s` |
| W2 | Self-hosted PE linker (future) |

Stub search: `CO_PEFF_LIB` then `CO_WINDOWS_LIB` then prefix `lib/copeff`.

Linker binary: `CO_PEFF_LINK`, else Windows host `link`, other hosts `lld-link`.
