# asmer/darwin

Mach-O object backend for `--target=darwin`.

## Role

- Input: AT&T `.s` from codegen (same instruction stream as linux)
- Output: Mach-O relocatable object (`.o`)

Self-hosted writer reuses Parser + instruct encoding; this package only emits the Mach-O container.

## Cases

```bash
bash asmer/darwin/cases/check_macho.sh
bash asmer/darwin/cases/check_rip_store.sh
```

Scripts skip (exit 0) when `uname` is not Darwin.

## Non-goals

- ELF to Mach-O translation
- Host `as` fallback
