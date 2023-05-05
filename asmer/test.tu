
use fmt
use asmer
use os 
use std
use utils
use elf
use parser
use ast
use instruct

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
                os.die(
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
    fmt.printf("ebuild passed] %s\n",filename )
}

func main()
{
    if(os.argc() > 1) return codegen(os.argv()[0])
    dir = "./cases"
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