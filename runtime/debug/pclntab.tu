// L0 pclntab: readonly PC -> func/file/line lookup (Phase1).
// Table lives in runtime_pclntab buffer; accessed via runtime.pclntab_addr.

use fmt
use string
use runtime

TU_PCLN_MAGIC<u32>  = 0xFFFFFFF1.(u32)
TU_PCLN_HDR_SIZE<u64> = 24.(u64)
TU_PCLN_REC_SIZE<u64> = 40.(u64)

// PcHeader v1 (first 24 bytes of .tupclntab).
mem PcHeader {
    u32 magic
    u8  min_lc
    u8  ptr_size
    u16 _pad
    u32 nfunc
    u32 nfiles
    u32 functab_off
    u32 _res0
}

// Phase1 function record (sorted by entry).
mem PclnRec {
    u64 entry
    u64 endv
    u64 name
    u64 file
    i32 line
    i32 pad
}

// Runtime view of the loaded table.
mem PclnTab {
    u64 base
    u32 nfunc
    i32 ready
}

g_pcln<PclnTab> = null

// Bind table from linker symbols; degrade quietly on bad magic.
fn pclntab_init() i8 {
    if g_pcln != null {
        return g_pcln.ready.(i8)
    }
    g_pcln = new PclnTab{
        base: 0.(u64),
        nfunc: 0.(u32),
        ready: 0
    }
    base<u64> = runtime.pclntab_addr()
    if base == 0.(u64) {
        return 0.(i8)
    }
    hdr<PcHeader> = base.(PcHeader)
    if hdr.magic != TU_PCLN_MAGIC {
        return 0.(i8)
    }
    g_pcln.base = base
    g_pcln.nfunc = hdr.nfunc
    g_pcln.ready = 1
    return 1.(i8)
}

// Binary search: largest entry <= pc with pc < end; copy record out of rodata.
fn findfunc(pc<u64>) PclnRec {
    if g_pcln == null || g_pcln.ready == 0 {
        return null
    }
    n<u32> = g_pcln.nfunc
    if n == 0.(u32) {
        return null
    }
    recs<u64> = g_pcln.base + TU_PCLN_HDR_SIZE
    lo<i32> = 0
    hi<i32> = n.(i32) - 1
    best<i32> = -1
    while lo <= hi {
        mid<i32> = (lo + hi) / 2
        off<u64> = recs + mid.(u64) * TU_PCLN_REC_SIZE
        r<PclnRec> = off.(PclnRec)
        if r.entry <= pc {
            best = mid
            lo = mid + 1
        } else {
            hi = mid - 1
        }
    }
    if best < 0 {
        return null
    }
    off2<u64> = recs + best.(u64) * TU_PCLN_REC_SIZE
    r2<PclnRec> = off2.(PclnRec)
    if pc >= r2.endv {
        return null
    }
    out<PclnRec> = new PclnRec{
        entry: r2.entry,
        endv: r2.endv,
        name: r2.name,
        file: r2.file,
        line: r2.line,
        pad: 0
    }
    return out
}

// Format one PC for backtrace: "name @ file:line" or "0xpc:??".
func pcln_format_pc(pc){
    r<PclnRec> = findfunc(pc.(u64))
    if r == null {
        return int(pc) + ":??"
    }
    name_s = "??"
    file_s = "??"
    if r.name != 0.(u64) {
        name_s = string.new(r.name)
    }
    if r.file != 0.(u64) {
        file_s = string.new(r.file)
    }
    return fmt.sprintf("%s @ %s:%d", name_s, file_s, int(r.line))
}
