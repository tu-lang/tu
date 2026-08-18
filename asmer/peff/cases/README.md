# Self-hosted Windows COFF golden cases

Assemble `.s` with self-hosted asmer and mother `tua --target=windows`, then compare.

- `empty_main.s` / `hex64.s`: instruction + data smoke
- `data_rip.s`: isolated `.long`/`.byte` RIP-relative load/store (RFC-107 D3.2)
- `empty.tu` / `hello.tu`: tiny programs for `tu.exe build --target=windows`

Run (Windows, after vcvars):

```
powershell -NoProfile -File asmer/peff/cases/run_golden.ps1
```

Byte-identical output is not required: mother `unordered_map` vs self-hosted name-sorted symbols can shuffle reloc indices. Structure must match (section sizes, symbol name set, reloc count).
