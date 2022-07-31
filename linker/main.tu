
use fmt
use link
use os 
use std
use utils

#[dir,dir,dir]
scan_dirs

#[file,file]
scan_files

# executable file name
out

func print_help(){
    fmt.println("usage: ./cld [options|file.o...]\n" +
                "  -p        指定扫描目录下所有.0文件进行链接生成可执行程序\n" +
                "  -d        debug\n" +
                "  -o [name] 指定生成的可执行文件名,默认tol\n" +
                "  file.o   ... 手动指定多个file.o进行链接\n"
    )
}

func link(){
    utils.debug("main.link")
    linker  = new link.Linker()
    for(obj : scan_files){
        # 添加目标文件
        linker.addElf(obj)
    }
    # 开始链接
    linker.link(out)
}

func scan(){
    utils.debug("main.scan")
    linker  = new link.Linker()

    for(dir : scan_dirs){
        if !std.is_dir(dir) os.die(dir + " not exist")
        # 迭代目录文件
        fd = std.opendir(dir)
        while true {
            file = std.readdir(fd)
            if !file break
            if !file.isFile() continue
            # 解析目标文件
            filename = file.path
            if string.sub(filename,std.len(filename) - 2) == ".o" {
                scan_files[] = file.path
            }
        }
    }
    total = std.len(scan_files)
    if total <= 0 utils.error("please provide at lease one .o file")

    i = 1
    //FIXME: for(file : scan_files)
    for(f : scan_files){
	    utils.smsg("[ " + i + "/" + total +"]","Reading elf object info " + f)
        linker.addElf(f)
        i += 1
    }
    # 开始链接
    linker.link(out)
    utils.msg(100,"Generate " + out + " Passed")
}

func command() {
    scan_dirs = []
    scan_files = []
    out = "a.out"
    i = 0
    while i < std.len(os.argv)  {
        match os.argv[i] {
            "-p" : {
                scan_dirs[] = os.argv[i+1]    # link dir
                i += 2
            }
            "-d" : {
                utils.debug_mode = 1          # debug mode
                i += 1
            }
            "-o" : {
                out = os.argv[i+1]
                i += 2
            }
            _ : {
                scan_files[] = os.argv[i+1]   # link object
                i += 1
            }
        }
    }
}

func main() {
    if  os.argc < 1 {
        return print_help()
    }
    command()  # parse command

    # link single files or scan dir
    if std.len(scan_dirs)        return scan()
    else if std.len(scan_files)  return scan()
    else                         return print_help()

}
