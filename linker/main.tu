use fmt
use linker.link
use linker.darwin
use linker.peff
use os 
use std
use string
use linker.utils
use runtime

link_target = 0

//[dir,dir,dir]
scan_dirs

//[file,file]
scan_files

// executable file name
out
out_set = 0

func print_help(){
    fmt.println("usage: ./cld [options|file.o...]\n" +
                "  -p        指定扫描目录下所有.0文件进行链接生成可执行程序\n" +
                "  -d        debug\n" +
                "  -o [name] 指定生成的可执行文件名,默认tol\n" +
                "  --target linux|darwin|windows  link backend (default: host / TU_TARGET)\n" +
                "  file.o   ... 手动指定多个file.o进行链接\n"
    )
}

func darwin_default_out() {
    if out_set != 0 {
        return
    }
    if link_target != 1 && link_target != 2 {
        return
    }
    name = "a.out"
    if link_target == 2 {
        name = "a.exe"
    }
    if std.len(scan_files) > 0 {
        out = utils.path_join(utils.path_dirname(scan_files[0]), name)
        return
    }
    if std.len(scan_dirs) > 0 {
        out = utils.path_join(scan_dirs[0], name)
    }
}

func link(){
    utils.debug("main.link")
    darwin_default_out()
    lt<i32> = link_target
    if lt == 1 {
        rc = darwin.link_objects(scan_files, out)
        if rc != 0 {
            utils.error("Generate " + out + " Failed")
        }
        utils.msg(100,"Generate " + out + " Passed")
        return
    }
    if lt == 2 {
        rc = peff.link_objects(scan_files, out)
        if rc != 0 {
            utils.error("Generate " + out + " Failed")
        }
        utils.msg(100,"Generate " + out + " Passed")
        return
    }
    linker  = new link.Linker()
    for(obj : scan_files){
        linker.addElf(obj)
    }
    linker.link(out)
}

func scan(){
    utils.debug("main.scan")
    darwin_default_out()
    linker  = new link.Linker()

    for(dir : scan_dirs){
        if !std.is_dir(dir) os.die(dir + " not exist")
        fd = std.opendir(dir)
        loop {
            file = fd.readdir()
            if !file break
            if !file.isFile() continue
            filename = file.path
            if string.sub(filename,std.len(filename) - 2) == ".o" {
                scan_files[] = file.path
            }
        }
    }
    total = std.len(scan_files)
    if total <= 0 utils.error("please provide at lease one .o file")

    if link_target == 1 {
        rc = darwin.link_objects(scan_files, out)
        if rc != 0 {
            utils.error("Generate " + out + " Failed")
        }
        utils.msg(100,"Generate " + out + " Passed")
        return
    }
    if link_target == 2 {
        rc = peff.link_objects(scan_files, out)
        if rc != 0 {
            utils.error("Generate " + out + " Failed")
        }
        utils.msg(100,"Generate " + out + " Passed")
        return
    }

    i = 1
    for f : scan_files {
	    utils.smsg("[ " + i + "/" + total +"]","Reading elf object info " + f)
        linker.addElf(f)
        i += 1
    }
    if !linker.link(out) {
        utils.error("Generate " + out + " Failed")
    }
    utils.msg(100,"Generate " + out + " Passed")
}

func link_target_default() {
    for (k, v : os.envs()) {
        arr = string.split(v, "=")
        if std.len(arr) >= 2 {
            if arr[0] == "TU_TARGET" || arr[0] == "CO_TARGET" {
                if arr[1] == "darwin" || arr[1] == "macos" || arr[1] == "osx" {
                    return 1
                }
                if arr[1] == "windows" || arr[1] == "win64" || arr[1] == "pe" {
                    return 2
                }
                if arr[1] == "linux" {
                    return 0
                }
            }
        }
    }
    // Dynamic 0/1/2 — native i32 0 from host_os() is a null Value*.
    if runtime.host_os() == 1 {
        return 1
    }
    if runtime.host_os() == 2 {
        return 2
    }
    return 0
}
func command() {
    scan_dirs = []
    scan_files = []
    out = "a.out"
    out_set = 0
    link_target = link_target_default()
    if link_target == 2 {
        out = "a.exe"
    }
    i = 0
    av = os.argv()
    // Skip argv[0] program path (same as tulang / asmer after macos argv unify).
    if std.len(av) > 0 {
        a0 = av[0]
        if a0 != "-p" && a0 != "-d" && a0 != "-o" && a0 != "--target" {
            if std.len(a0) == 0 || a0[0] != '-' {
                i = 1
            }
        }
    }
    while i < std.len(av)  {
        arg = av[i]
        if std.len(arg) > 9 {
            pref = "--target="
            pref_ok = true
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
                name = string.sub(arg, tpos)
                if name == "darwin" || name == "macos" || name == "osx" {
                    link_target = 1
                } else if name == "windows" || name == "win64" || name == "pe" {
                    link_target = 2
                    if out_set == 0 {
                        out = "a.exe"
                    }
                } else if name == "linux" {
                    link_target = 0
                }
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
                link.trace = true
                i += 1
            }
            "-o" : {
                out = av[i+1]
                out_set = 1
                i += 2
            }
            "--target" : {
                name = av[i+1]
                if name == "darwin" || name == "macos" || name == "osx" {
                    link_target = 1
                } else if name == "windows" || name == "win64" || name == "pe" {
                    link_target = 2
                    if out_set == 0 {
                        out = "a.exe"
                    }
                } else if name == "linux" {
                    link_target = 0
                }
                i += 2
            }
            _ : {
                arg = av[i]
                n = std.len(arg)
                is_obj = false
                if n >= 2 {
                    if arg[n - 2] == '.' && arg[n - 1] == 'o' {
                        is_obj = true
                    }
                }
                if is_obj {
                    scan_files[] = arg
                } else {
                    scan_dirs[] = arg
                }
                i += 1
            }
        }
    }
}

func main() {
    if  os.argc() < 1 {
        return print_help()
    }
    command()  // parse command

    // link single files or scan dir
    if std.len(scan_dirs)        return scan()
    else if std.len(scan_files)  return link()
    else                         return print_help()

}
