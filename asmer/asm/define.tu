use asmer.elf
use asmer.parser

mem Asmer
{
    parser.Parser*   parser
    u64*             out
    elf.ElfFile*     elf
    i32              data ,text
    i32              bytes
}
trace<i64> = 0
Pad1<i64> = 1
