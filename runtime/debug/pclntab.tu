// L0 pclntab v2: PC -> func/file/line + framesize (pcsp subset for RBP-less walk).

use fmt
use string
use runtime

TU_PCLN_MAGIC<u32>  = 0xFFFFFFF2.(u32)
TU_PCLN_HDR_SIZE<u64> = 24.(u64)
TU_PCLN_REC_SIZE<u64> = 48.(u64)

// PcHeader v1 layout (first 24 bytes); magic selects v2 record size.
mem PcHeader {
    u32 magic
    u8  min_lc
    u8  ptr_size
    u16 _pad
    u32 nfunc
    u32 nfiles
    u32 functab_off
    u32 pctab_off
}

// Function record; framesize = 16+stack_size for standard frames.
mem PclnRec {
    u64 entry
    u64 endv
    u64 name
    u64 file
    i32 line
    u32 pcln_off
    u32 framesize
    u32 _pad
}

mem PclnTab {
    u64 base
    u32 nfunc
    i32 ready
}

g_pcln<PclnTab> = null

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

// Binary search function covering pc; copy record out of table.
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
        pcln_off: r2.pcln_off,
        framesize: r2.framesize,
        _pad: 0.(u32)
    }
    return out
}

mem PclnLineHdr {
    u32 n
}

mem PclnLineEnt {
    u32 pc_off
    i32 line
}

fn funcline(r<PclnRec>, pc<u64>) i32 {
    if r == null {
        return 0
    }
    line<i32> = r.line
    if r.pcln_off == 0.(u32) {
        return line
    }
    if g_pcln == null {
        return line
    }
    tab<u64> = g_pcln.base + r.pcln_off.(u64)
    hdr<PclnLineHdr> = tab.(PclnLineHdr)
    nent<u32> = hdr.n
    if nent == 0.(u32) {
        return line
    }
    off<u64> = 0.(u64)
    if pc >= r.entry {
        off = pc - r.entry
    }
    i<u32> = 0.(u32)
    while i < nent {
        ent_bits<u64> = tab + 4.(u64) + i.(u64) * 8.(u64)
        ent<PclnLineEnt> = ent_bits.(PclnLineEnt)
        if ent.pc_off.(u64) <= off {
            line = ent.line
            i = i + 1.(u32)
        } else {
            break
        }
    }
    return line
}

// FuncForPC / Caller helpers (Phase6).
fn FuncForPC(pc<u64>) PclnRec {
    return findfunc(pc)
}

fn funcname(r<PclnRec>) {
    if r == null || r.name == 0.(u64) {
        return "??"
    }
    return string.new(r.name)
}

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
    ln<i32> = funcline(r, pc.(u64))
    return fmt.sprintf("%s @ %s:%d", name_s, file_s, int(ln))
}
