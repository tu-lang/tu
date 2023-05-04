
use fmt
use asmer
use os 
use std
use utils
use elf

func codegen(filename){
    fmt.printf("[buiding] %s\n",filename)
    // return
    exb = string.split(filename,".s")
    phb = exb[0] + ".i"
    
    
    ph = new ParseHexBytes(phb)
    expect_bytes = ph.parse()
    elf   = new elf.ElfFile(nullptr)
    gen = new parser.Parser(filename,elf)
    gen.parse()
    p<i8*> = expect_bytes.data()
    psize<i32> = 0
    for(block : gen.funcs){
        for(inst : block.instructs){
            if(psize >= expect_bytes.len())
                fmt.printf("[error] %d:%d overflow\n",expect_bytes.len(),psize)
            ret<i32> = std.memcmp(p,inst.bytes,inst.size)
            if(ret != 0){
                os.die("  ")
            }
            p += inst.size
            psize += inst.size
        }
    }
    fmt.printf("ebuild passed] %s\n",filename))
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