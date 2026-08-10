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
// Driver-requested target name ("linux"/"darwin"); empty → host_os().
requested_target = ""
