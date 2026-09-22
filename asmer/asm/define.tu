use asmer.elf
use asmer.parser

TARGET_LINUX<i32>   = 0
TARGET_DARWIN<i32>  = 1
TARGET_WINDOWS<i32> = 2

mem Asmer
{
    parser.Parser*   parser
    u64*             out
    elf.ElfFile*     elf
    i32              data ,text
    i32              bytes
    i32              target
}
trace<i64> = 0
Pad1<i64> = 1
// Driver-requested target name ("linux"/"darwin"/"windows"); empty → host_os().
requested_target = ""

// Dyn-callable accessors for tulang / tua drivers (static package export facades).
export func get_requested_target() {
    return requested_target
}
export func set_requested_target(name) {
    requested_target = name
}