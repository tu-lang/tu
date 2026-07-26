// Bridges into the library `runtime` package for callers in asyncio.runtime.
//
// The parent package short-name is also `runtime`. Importing the library as
// `use runtime` / `use runtime as alias` registers path "runtime" in the parent
// import table; getPackage then treats structpkg "runtime" as the library and
// local mem types (Builder, CachedParkThread, …) stop resolving. Subpackages
// (short-name `blocking`) can safely `use runtime` and re-export the few
// entrypoints the parent needs — same Note / newcore primitives the design uses.

use runtime

// Spawn an OS thread for entry.
fn librt_newcore(entry<u64>) {
    runtime.newcore(entry)
}

// Note helpers as raw u64 bits.
fn librt_note_new_raw() u64 {
    return runtime.note_new_raw()
}

fn librt_note_wake_raw(bits<u64>) {
    runtime.note_wake_raw(bits)
}

fn librt_note_sleep_raw(bits<u64>) {
    runtime.note_sleep_raw(bits)
}

fn librt_note_clear_raw(bits<u64>) {
    runtime.note_clear_raw(bits)
}
