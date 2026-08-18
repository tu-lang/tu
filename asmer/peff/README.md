# asmer/peff

PE/COFF object backend for `--target=windows` (aliases `peff` / `win64` / `pe`).

Public dispatch lives in `asmer/asm/asmer.tu`; this directory serializes Parser + instruct bytes into a COFF relocatable.

## Role

- Input: AT&T `.s` (same instruction stream as linux/darwin)
- Output: COFF `.o` (`IMAGE_FILE_MACHINE_AMD64`)
- Relocs: `IMAGE_REL_AMD64_REL32` / `ADDR64`; undefined symbols stay `IMAGE_SYM_UNDEFINED`

## Cases

`asmer/peff/cases/` holds `empty_main.s` and `hex64.s` for golden compare against mother `tua --target=windows`.

## Phase

| Phase | Status |
|-------|--------|
| W1 COFF writer | Done; host link is `linker/peff` |
| W2 self-hosted PE linker | Future |
