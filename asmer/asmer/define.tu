use elf
use parser

mem Asmer
{
    parser.Parser*   parser
    u64*             out
    elf.ElfFile*     elf
    i32              data ,text
    i32              bytes
}
