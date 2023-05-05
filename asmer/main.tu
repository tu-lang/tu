
use fmt
use asmer
use os 
use std
use utils

#[dir,dir,dir]
scan_dirs

#[file,file]
scan_files

func print_help () {
    fmt.println(
        "usage: ./ta [options] file.s  可用的选项:\n" + 
        "  *.s      翻译汇编为cpu指令，并生成可重定向elf二进制文件\n" +
        "  -p ...   批量翻译汇编为cpu指令，并生成可重定向elf二进制文件\n" +
        "  -x       打印编译过程信息信息\n"
    )
}
func asmergen(){
    utils.debug(*"main.asmergen")
    for(dir : scan_dirs){
        if !std.is_dir(dir) os.die(dir + " not exist")
        fd = std.opendir(dir)
        loop {
            file = fd.readdir()
            if !file break
            if !file.isFile() continue
            filename = file.path
            if string.sub(filename,std.len(filename) - 2) == ".s" {
                scan_files[] = file.path
            }
        }
    }
    total = std.len(scan_files)
    if total <= 0 utils.error("please provide at lease one .o file")
    //start gen
    i = 1
    for f : scan_files {
	    utils.smsg("[ " + i + "/" + total +"]","Compiling asm file " + f)
        eng<asmer.Asmer> = new asmer.Asmer(f)
        eng.execute()
	    utils.smsg("[ " + i + "/" + total +"]",
            fmt.sprintf("Generate %s Passed" ,eng.parser.outname)
        )
        i += 1
    }
    utils.msg(100,"Generate all Passed")
}

func command() {
    scan_dirs = []
    scan_files = []
    i = 0
    while i < std.len(os.argv())  {
        match os.argv()[i] {
            "-p" : {
                scan_dirs[] = os.argv()[i+1]    # asm dir
                i += 2
            }
            "-x" : {
                utils.debug_mode = 1          # debug mode
                i += 1
            }
            _ : {
                scan_files[] = os.argv()[i]   # link object
                i += 1
            }
        }
    }
}
func main() {
    if  os.argc() < 1 {
        return print_help()
    }
    command()  # parse command

    # compile single asm files or scan dir
    if std.len(scan_dirs)        return asmergen()
    else if std.len(scan_files)  return asmergen()
    else                         return print_help()
}