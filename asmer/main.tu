
use fmt
use asmer.asm
use os 
use std
use string
use asmer.utils
use runtime

#[dir,dir,dir]
scan_dirs

#[file,file]
scan_files

as_target = 0

func print_help () {
    fmt.println(
        "usage: ./ta [options] file.s  可用的选项:\n" + 
        "  *.s      翻译汇编为cpu指令，并生成可重定向elf二进制文件\n" + 
        "  -c *.s   翻译单个汇编文件（与 -c 前的路径等价）\n" +
        "  -p ...   批量翻译汇编为cpu指令，并生成可重定向elf二进制文件\n" +
        "  -d       打印编译过程信息信息\n" +
        "  --target linux|darwin|windows   object backend (default: host / TU_TARGET)\n"
    )
}
func asmergen(){
    utils.debug(*"main.asmergen")
    for(dir : scan_dirs){
        if !std.is_dir(dir) os.die(dir + " not exist")
        names = utils.list_basenames(dir)
        for name : names {
            if name == "." || name == ".." {
                continue
            }
            nlen = std.len(name)
            if nlen < 2 {
                continue
            }
            if string.sub(name, nlen - 2) != ".s" {
                continue
            }
            path = utils.path_join(dir, name)
            scan_files[] = path
        }
    }
    total = std.len(scan_files)
    if total <= 0 utils.error("please provide at lease one .o file")
    //start gen
    i = 1
    for f : scan_files {
	    utils.smsg("[ " + i + "/" + total +"]","Compiling asm file " + f)
        eng<asm.Asmer> = new asm.Asmer(f)
        eng.execute()
        eng.close()
	    utils.smsg("[ " + i + "/" + total +"]",
            fmt.sprintf("Generate %s Passed" ,eng.parser.outname)
        )
        i += 1
    }
    utils.msg(100,"Generate all Passed")
}

func parse_as_target(name) {
    asm.requested_target = name
    if name == "darwin" || name == "macos" || name == "osx" {
        // Dynamic return must be a boxed int; native TARGET_* (0) is a null Value*.
        return 1
    }
    if name == "linux" {
        return 0
    }
    if name == "windows" || name == "win64" || name == "pe" {
        return 2
    }
    os.die("unknown --target=" + name)
}
func as_target_default() {
    for (k, v : os.envs()) {
        arr = string.split(v, "=")
        if std.len(arr) >= 2 {
            if arr[0] == "TU_TARGET" || arr[0] == "CO_TARGET" {
                if arr[1] == "darwin" || arr[1] == "macos" || arr[1] == "osx" || arr[1] == "linux" || arr[1] == "windows" || arr[1] == "win64" || arr[1] == "pe" {
                    parse_as_target(arr[1])
                    return
                }
            }
        }
    }
    if runtime.host_os() == 1 {
        asm.requested_target = "darwin"
    } else if runtime.host_os() == 2 {
        asm.requested_target = "windows"
    } else {
        asm.requested_target = "linux"
    }
}
func command() {
    scan_dirs = []
    scan_files = []
    as_target_default()
    // Dynamic as_target: use 0/1 literals (asm.TARGET_LINUX is i32 0 → null Value*).
    as_target = 0
    if asm.requested_target == "darwin" || asm.requested_target == "macos" || asm.requested_target == "osx" {
        as_target = 1
    }
    if asm.requested_target == "windows" || asm.requested_target == "win64" || asm.requested_target == "pe" {
        as_target = 2
    }
    i = 0
    av = os.argv()
    // Darwin ori_argv keeps argv[0] (program path); Linux entry now matches.
    if std.len(av) > 0 {
        a0 = av[0]
        if a0 != "-p" && a0 != "-c" && a0 != "-d" && a0 != "--target" {
            // Skip program path; flags start with '-'.
            if std.len(a0) == 0 || a0[0] != '-' {
                i = 1
            }
        }
    }
    while i < std.len(av)  {
        arg = av[i]
        if std.len(arg) > 9 {
            pref_ok = true
            pref = "--target="
            j = 0
            while j < 9 {
                if arg[j] != pref[j] {
                    pref_ok = false
                    break
                }
                j += 1
            }
            if pref_ok {
                tpos = 9
                as_target = parse_as_target(string.sub(arg, tpos))
                i += 1
                continue
            }
        }
        match arg {
            "-p" : {
                scan_dirs[] = av[i+1]
                i += 2
            }
            "-d" : {
                asm.trace = true
                i += 1
            }
            "-c" : {
                i += 1
            }
            "--target" : {
                as_target = parse_as_target(av[i+1])
                i += 2
            }
            _ : {
                scan_files[] = av[i]
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