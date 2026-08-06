
use fmt
use os 
use std
use asmer.utils
use asmer.elf
use asmer.parser
use asmer.ast
use asmer.instruct

func codegen(filename){
    fmt.printf("[buiding] %s\n",filename)
    // return
    exb = string.split(filename,".s")
    phb = exb[0] + ".i"
    
    ph<utils.ParseHexBytes> = new utils.ParseHexBytes(phb)
    //bytes
    expect_bytes<std.Array> = ph.parse()
    // ph.print()
    gen<parser.Parser> = new parser.Parser(
        filename,
        new elf.ElfFile(0.(i8))
    )
    gen.parse()
    p<u8*> = expect_bytes.addr
    psize<i32> = 0
    buf_o<i8:10> = null
    buf<i8*>	 = &buf_o
    for(i<i32> = 0 ; i < gen.funcs.len() ; i += 1) {
        block<ast.Function> = gen.funcs.addr[i]
        for(j<i32> = 0 ; j < block.instructs.len() ; j += 1){
            inst<instruct.Instruct> = block.instructs.addr[j]
            if psize >= expect_bytes.len() 
                utils.errorf(
                    "[error] %d:%d overflow",
                    int(expect_bytes.len()),
                    int(psize)
                )
            ret<i32> = std.memcmp(p,&inst.bytes,inst.size)
            if(ret != 0){
                utils.printf("str:%S\n".(i8),inst.str.str())
                utils.printf("inst:\t".(i8))
                for(k<i32> = 0 ; k < inst.size; k += 1){
                    std.itoa(inst.bytes[k],buf,16.(i8))
                    utils.printf("%s ".(i8),buf)
                }
                utils.printf("\ncorr:\t".(i8))
                for( k<i32> = 0 ; k < inst.size; k += 1){
                    std.itoa(p[k],buf,16.(i8))
                    utils.printf("%s ".(i8),buf)
                }
                os.dief(
                    "failed asmer gen(%d): line:%d column:%d\n",
                    int(psize),
                    int(inst.line),
                    int(inst.column)
                )
            }
            p += inst.size
            psize += inst.size
        }
    }
    // .balign/.align/.p2align: lock .data offsets (see co/asmer/test.cpp).
    if string.sub(filename, std.len(filename) - 8) == "balign.s" {
        check_balign_layout(gen)
    }
    fmt.printf("[all test passed] %s\n",filename )
}

func check_balign_layout(gen){
    // "x\\0"(2)+pad6→aligned8@8; +"ab\\0"(3)=19+pad1→aligned4@20;
    // +long4=24→aligned_p2@24; +quad8=32→already8@32.
    pgen<parser.Parser> = gen
    expect_one(pgen, "oddstr", 0.(i32))
    expect_one(pgen, "aligned8", 8.(i32))
    expect_one(pgen, "odd2", 16.(i32))
    expect_one(pgen, "aligned4", 20.(i32))
    expect_one(pgen, "aligned_p2", 24.(i32))
    expect_one(pgen, "already8", 32.(i32))
}

func expect_one(pgen<parser.Parser>, name, want<i32>){
    data_symbol<std.Array> = pgen.symtable.data_symbol
    for(i<i32> = 0; i < data_symbol.len(); i += 1) {
        sym<ast.Sym> = data_symbol.addr[i]
        n = string.new(sym.name.str())
        if n == name {
            if sym.addr != want {
                os.dief("[balign] %s addr=%d want=%d", name, int(sym.addr), int(want))
            }
            return
        }
    }
    os.dief("[balign] missing sym %s", name)
}

func main()
{
    if(os.argc() > 1) return codegen(os.argv()[0])
    dir = "./asmer/cases"
    if !std.is_dir(dir) os.die(dir + " not exist")
    fd = std.opendir(dir)
    loop {
        file = fd.readdir()
        if !file break
        if !file.isFile() continue
        filename = file.path
        if string.sub(filename,std.len(filename) - 2) == ".s" {
            codegen(file.path)
        }
    }
    fmt.println("all passed")
}
