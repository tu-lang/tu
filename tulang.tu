use fmt
use os 
use std
use compiler.utils
use compiler.compile
use compiler.parser
use asmer.asm
use linker.link
use linker.darwin
use linker.peff
// Prefix for coasm / copkg / copeff. Overridden by CO_PREFIX / TU_PREFIX / CO_PKG.
root = "/usr/local/lib"
printlat = false

// RFC-107 Phase B: stdroot embedded at tu link time (paths relative to repo root).
// Untyped: embed() yields the dynamic EmbedFSObj (read/list) consumed by compiler.utils pkgfs.
stdroot_embed = embed("library", "packages", "runtime", "syscall", "platform")

// Mother tuc parity: foo.tu → foo (windows → foo.exe).
func build_output_name(file) {
	base = utils.path_basename(file)
	dest = ""
	n = std.len(base)
	if n >= 3 {
		ext = string.sub(base, n - 3)
		if ext == ".tu" {
			dest = ""
			i = 0
			while i < n - 3 {
				dest = dest + base[i]
				i = i + 1
			}
		}
	}
	if dest == "" {
		if base != "" {
			dest = base
		} else if utils.target_parse(asm.get_requested_target()) == utils.TARGET_WINDOWS {
			dest = "a.exe"
		} else {
			dest = "a.out"
		}
	}
	if utils.target_parse(asm.get_requested_target()) == utils.TARGET_WINDOWS {
		dn = std.len(dest)
		if dn < 4 || string.sub(dest, dn - 4) != ".exe" {
			dest = dest + ".exe"
		}
	}
	return dest
}

class Compiler {
    // origin file
    code_files = []
    scan_dirs  = []
    // After -s codegen: also asmer+link (used by build / run)
    flag_link = false
    // After link: execute a.out (tu run)
    flag_exec = false
    // Args forwarded to the linked binary when flag_exec
    args = []
    // Exit code of the binary run by `tu run`; tu exits with it.
    exit_code = 0
    // compiler || asmer || linker  
    // default compiler
    type = "compiler"
    flag_gcc  = false
    flag_nostd_explicit = false
    //default executeable name
    out       = "a.out"
    // workdir: default TMPDIR/tu-build-*; --workdir-cwd or --workdir DIR
    workdir_cwd = false
    workdir_explicit = ""
    // Keep .s/.o after build when --work is set
    flag_work = false
    // -1 unset (follow env); 0 embed; 1 disk. Explicit --stdlib= overrides TU_STDLIB.
    stdlib_mode = -1
}
func arg_after_prefix(arg, n) {
    out = ""
    i = n
    alen = std.len(arg)
    while i < alen {
        out += arg[i]
        i += 1
    }
    return out
}
func arg_has_prefix(arg, pref) {
    n = std.len(pref)
    if std.len(arg) < n {
        return false
    }
    j = 0
    while j < n {
        if arg[j] != pref[j] {
            return false
        }
        j += 1
    }
    return true
}
Compiler::init() {
    // Target lives in asm.get_requested_target() (string). Avoid class i32 0 traps.
    asm.set_requested_target(utils.target_name(utils.target_default()))
    // copkg/coasm: env override, else dirname(dirname(exe))/lib (install layout).
    root = utils.lib_root()
}
Compiler::apply_target(name) {
    if name == "linux" || name == "darwin" || name == "macos" || name == "osx" || name == "windows" || name == "win64" || name == "pe" {
        asm.set_requested_target(name)
        return
    }
    fmt.printf("[tu] unknown --target=%s (want linux|darwin|windows)\n", name)
    os.exit(-1)
}
Compiler::print_help(){
    // Column-aligned help (avoid fmt.println: it appends a trailing tab).
    fmt.printf(
        "Usage: tu <command|option> [arguments]\n" +
        "\n" +
        "Commands:\n" +
        "  run   <file.tu> [args...]  编译、链接并运行\n" +
        "  build <file.tu>            编译并链接生成可执行文件\n" +
        "\n" +
        "Options:\n" +
        "  -s   <file.tu|dir>         编译为 amd64 汇编（.s）\n" +
        "  -c   <file.s|dir>          汇编为可重定位目标文件（.o）\n" +
        "  -o   <file.o|dir>          链接目标文件生成可执行程序\n" +
        "  -d                         开启 trace 日志\n" +
        "  -gcc                       使用 gcc 链接\n" +
        "  -strip-pcln-file           pclntab 不写入文件名\n" +
        "  -std                       同时编译 runtime/std 内置库\n" +
        "  --workdir DIR              中间产物写到 DIR（.s/.o/a.out）\n" +
        "  --workdir-cwd              中间产物写当前目录（旧行为）\n" +
        "  --work                     保留中间产物\n" +
        "  --target linux|darwin|windows  对象/链接后端（默认=host；可用 TU_TARGET）\n" +
        "  --stdlib embed|disk            标准库来源（默认 embed）\n" +
        "  -v, --version                  打印版本\n" +
        "\n" +
        "Default workdir: $TMPDIR/tu-build-<stem>-... (removed after build/run unless --work)\n" +
        "tu run exits with the program's exit code.\n"
    )
}
Compiler::commadparse(){
    av = os.argv()
    i = 0
    // Darwin ori_argv keeps argv[0] (program path); Linux already dropped it.
    if std.len(av) > 0 {
        a0 = av[0]
        if a0 != "run" && a0 != "build" && !arg_has_prefix(a0, "-") {
            i = 1
        }
    }
    while i < std.len(av)  {
        arg = av[i]
        if arg_has_prefix(arg, "--target=") {
            preflen = std.len("--target=")
            this.apply_target(arg_after_prefix(arg, preflen))
            i += 1
            continue
        }
        if arg_has_prefix(arg, "--stdlib=") {
            preflen = std.len("--stdlib=")
            val = arg_after_prefix(arg, preflen)
            if val == "disk" {
                this.stdlib_mode = 1
            } else if val == "embed" {
                this.stdlib_mode = 0
            }
            i += 1
            continue
        }
        match arg {
            "run" : {
                this.type = "compiler"
                this.flag_link = true
                this.flag_exec = true
                this.code_files[] = os.argv()[i + 1]
                i += 1
            }
            "build" : {
                this.type = "compiler" 
                this.flag_link = true
                this.code_files[] = os.argv()[i + 1]
                i += 1
            }
            "-s" : {
                this.type = "compiler"
                this.scandir(os.argv()[i+1],".tu")
                i += 1
            }
            "-c" : {
                this.type = "asmer"
                this.scandir(os.argv()[i+1],".s")
                i += 1
            }
            "-o" : {
                this.type = "linker"
                this.scandir(os.argv()[i+1],".o")
                i += 1
            }
            "-d"  : {
                compile.trace = true          // trace mode && print log
                unsafe {
                    asm.trace  = 1
                    link.trace = 1
                }
            }
            "-g"   : compile.debug    = true
            "-std" : compile.nostd = false
            "-nostd" : {
                compile.nostd = true
                this.flag_nostd_explicit = true
            }
            "-gcc" : this.flag_gcc = true
            "-strip-pcln-file" : {
                unsafe {
                    link.strip_pcln_file = 1
                }
            }
            "-lat" : printlat = true
            "--workdir-cwd" : this.workdir_cwd = true
            "--work" : this.flag_work = true
            "--workdir" : {
                this.workdir_explicit = os.argv()[i + 1]
                i += 1
            }
            "--target" : {
                this.apply_target(os.argv()[i + 1])
                i += 1
            }
            "--stdlib" : {
                val = os.argv()[i + 1]
                if val == "disk" {
                    this.stdlib_mode = 1
                } else if val == "embed" {
                    this.stdlib_mode = 0
                }
                i += 1
            }
            "-v" | "--version" : {
                utils.print_version_report(asm.get_requested_target())
                os.exit(0)
            }
            _     : {
                // After `run <file.tu>`, leftover tokens are program argv.
                if this.flag_exec {
                    this.args[] = os.argv()[i]
                }else{
                    this.print_help()
                    fmt.println(utils.print_red(
                        fmt.sprintf("unkown option [%s]",os.argv()[i])
                    ))
                    os.exit(-1)
                }
            }
        }
        i += 1
    }
}
Compiler::scandir(dir,dstext){
    utils.debugf("main.scandir %s ext:%s",dir,dstext)
    //check is dir or codefile
    if !std.is_dir(dir) {
        utils.debugf("main.scandir: %s is file ",dir)
        this.code_files[] = dir
        return true
    }
    // Windows: std.opendir/readdir rely on getdents (ENOSYS); use FindFirst.
    names = utils.list_dir_basenames(dir)
    extlen = std.len(dstext)
    for name : names {
        if name == "." || name == ".." {
            continue
        }
        flen = std.len(name)
        if flen < extlen {
            continue
        }
        if string.sub(name, flen - extlen) != dstext {
            continue
        }
        path = utils.path_join(dir, name)
        if std.is_dir(path) {
            continue
        }
        utils.debugf("main.scandir: add %s ", path)
        this.code_files[] = path
    }
}
Compiler::compiler(file){
    utils.debug("main.compiler")
    // Relative paths are cwd only (same as linux/darwin). Do not
    // search $HOME / USERPROFILE, and do not create a TEMP workdir
    // if the source is missing.
    if file == null || file == "" || !std.is_file(file) {
        os.die("error opening file :" + file)
    }
    utils.msg2(10,"Compiling",fmt.sprintf(
        "%s v0.0.0",file
    ))
    if compile.nostd && !this.flag_gcc {
        compile.nostd = true
    }
    // run/build: compile std+coasm from embed (or disk) unless user passed -nostd.
    // Linux no longer defaults to prefix colib; -nostd still links colib when present.
    if this.flag_link && !this.flag_nostd_explicit {
        compile.nostd = false
    }
    compile.initWorkdir(file, this.workdir_cwd, this.workdir_explicit)
    compile.genast(file)
    compile.editast()
    compile.compile()
    utils.msg(30,"Compiler generate all Passed")
    wd = utils.workdir
    if wd == null || wd == "" {
        wd = "."
    }
    exe_name = "a.out"
    if utils.target_parse(asm.get_requested_target()) == utils.TARGET_WINDOWS {
        exe_name = "a.exe"
    }
    if this.flag_link {
        if utils.target_parse(asm.get_requested_target()) == utils.TARGET_DARWIN && this.flag_gcc {
            utils.error("-gcc is linux-only; use the self-hosted darwin linker")
        }
        if utils.target_parse(asm.get_requested_target()) == utils.TARGET_WINDOWS && this.flag_gcc {
            utils.error("-gcc is not supported for --target=windows; use the self-hosted peff linker")
        }
        //By Gcc Link
        if this.flag_gcc {
            compile.gcclink()
            if !this.flag_work {
                utils.remove_files_ext(wd, ".s")
            }
            if utils.target_parse(asm.get_requested_target()) != utils.TARGET_WINDOWS {
                os.shell("chmod 777 '" + utils.pathInWorkdir(exe_name) + "'")
            }
        }else {
        // Self asmer+linker: copy coasm .s into workdir (embed stdroot or disk
        // prefix). Never write .o back into prefix coasm*.
            this.code_files = []
            if !compile.nostd {
                // RFC-107: default embed materialize → syscall/{,darwin,windows}/.
                src = utils.pkgfs_coasm_dir()
                probe = utils.path_join(src, "asm_amd64.s")
                if !std.is_file(probe) {
                    utils.error("missing coasm asm_amd64.s at " + src)
                }
                utils.copy_dir_ext(src, wd, ".s")
            }
            this.scandir(wd,".s")
            this.asmer()

            this.code_files = []
            if compile.nostd && utils.target_parse(asm.get_requested_target()) != utils.TARGET_DARWIN && utils.target_parse(asm.get_requested_target()) != utils.TARGET_WINDOWS {
                utils.copy_dir_ext(root + "/colib", wd, ".o")
            }
            this.scandir(wd,".o")
            this.out = utils.pathInWorkdir(exe_name)
            this.linker()
            if !this.flag_work {
                utils.remove_files_ext(wd, ".o")
                utils.remove_files_ext(wd, ".s")
            }
        }
        if utils.target_parse(asm.get_requested_target()) != utils.TARGET_WINDOWS {
            os.shell("chmod 777 '" + utils.pathInWorkdir(exe_name) + "'")
        }
        if this.flag_work {
            fmt.printf("[tu] work: keeping %s\n", wd)
        }
    }
    exe = utils.pathInWorkdir(exe_name)
    // `tu build`: copy product to cwd (same as mother tuc); workdir may be removed.
    if this.flag_link && !this.flag_exec {
        dest = build_output_name(file)
        fmt.printf("[tu] copy %s -> ./%s\n", exe, dest)
        crc = utils.copy_file(exe, dest)
        if crc != 0 {
            utils.error("build: copy to ./" + dest + " failed")
        }
        if utils.target_parse(asm.get_requested_target()) != utils.TARGET_WINDOWS {
            os.shell("chmod 777 './" + dest + "'")
        }
        fmt.printf("[tu] build: ./%s\n", dest)
        exe = dest
    }
    utils.msg2(100,"Finished",fmt.sprintf(
        "%s target(%s)",file, exe
    ))
    // `tu run`: execute linked binary
    if this.flag_exec {
        if utils.target_parse(asm.get_requested_target()) == utils.TARGET_WINDOWS || utils.is_windows_host() {
            cmd = exe
            for a : this.args {
                cmd += " " + a
            }
            fmt.println(cmd)
            this.exit_code = utils.host_run(cmd)
        } else {
            cmd = "'" + exe + "'"
            for a : this.args {
                cmd += " '" + a + "'"
            }
            fmt.println(cmd)
            this.exit_code = utils.host_run(cmd)
        }
    }
    // build copied the product to cwd and run already executed it, so the
    // private TMPDIR workdir is no longer needed (--work keeps it).
    if this.flag_link && !this.flag_work {
        utils.cleanupWorkdir()
    }
}
Compiler::asmer(){
    total = std.len(this.code_files)
    if total <= 0 utils.error("please provide at lease one .o file")
    //start gen
    i = 1
    for f : this.code_files {
	    utils.smsg("[ " + i + "/" + total +"]","Compiling asm file " + f)
        outname = asm.assemble_file(f)
	    utils.smsg("[ " + i + "/" + total +"]",
            fmt.sprintf("Generate %s Passed" ,outname)
        )
        i += 1
    }
    utils.msg(100,"Aasmer generate all Passed")
}
Compiler::linker(){
    total = std.len(this.code_files)
    if total <= 0 utils.error("please provide at lease one .o file")

    // Default outfile next to the first .o, same as tul.
    if this.out == "a.out" && total > 0 {
        name = "a.out"
        if utils.target_parse(asm.get_requested_target()) == utils.TARGET_WINDOWS {
            name = "a.exe"
        }
        this.out = utils.path_join(utils.path_dirname(this.code_files[0]), name)
    }
    fmt.printf("[tu] outfile: %s\n", this.out)

    if utils.target_parse(asm.get_requested_target()) == utils.TARGET_DARWIN {
        rc = darwin.link_files(this.code_files, this.out)
        if rc != 0 {
            utils.error("Generate " + this.out + " Failed")
        }
        utils.msg(100,"Generate " + this.out + " Passed")
        return
    }
    if utils.target_parse(asm.get_requested_target()) == utils.TARGET_WINDOWS {
        rc = peff.link_files(this.code_files, this.out)
        if rc != 0 {
            utils.error("Generate " + this.out + " Failed")
        }
        utils.msg(100,"Generate " + this.out + " Passed")
        return
    }

    // mem Linker: drive via export facades (dyn class call on mem → object_func_addr).
    lk = link.linker_new()
    i = 1
    for f : this.code_files {
	    utils.smsg("[ " + i + "/" + total +"]","Reading elf object info " + f)
        link.linker_add_elf(lk, f)
        i += 1
    }
    if link.linker_link(lk, this.out) == 0 {
        utils.error("Generate " + this.out + " Failed")
    }
    utils.msg(100,"Generate " + this.out + " Passed")
}
Compiler::compile(){
    if !std.len(this.code_files) {
        utils.error("missing code file")
    }
    match this.type {
        "compiler" : return this.compiler(this.code_files[0])
        "asmer"    : return this.asmer()
        "linker"   : return this.linker()
        _          : {
            fmt.println("unknown compile type:")
            return this.print_help()
        }
    }
}
func main() {
    start = std.ntime()
    eng = new Compiler()
    if os.argc() < 1 {
        return eng.print_help() 
    }
    os.set_stack(10)
    eng.commadparse() // handle options
    // RFC-107: default embed; TU_STD / TU_STDLIB=disk when CLI does not set --stdlib=
    // Explicit --stdlib=embed|disk always wins over env.
    pmode = utils.PKGFS_MODE_EMBED
    if eng.stdlib_mode == 1 {
        pmode = utils.PKGFS_MODE_DISK
    } else if eng.stdlib_mode == 0 {
        pmode = utils.PKGFS_MODE_EMBED
    } else {
        pmode = utils.pkgfs_parse_mode_from_env()
    }
    tu_std = utils.pkgfs_tu_std_from_env()
    if pmode == utils.PKGFS_MODE_EMBED && stdroot_embed == null {
        utils.notice("pkgfs: empty stdroot; falling back to disk")
        pmode = utils.PKGFS_MODE_DISK
    }
    utils.pkgfs_set_stdroot(stdroot_embed)
    tname = asm.get_requested_target()
    if tname == null || tname == "" {
        tname = utils.target_name(utils.target_default())
    }
    utils.pkgfs_configure_named(pmode, tu_std, tname)
    eng.compile()
    utils.pkgfs_cleanup()

    end = std.ntime()
    if printlat {
        latency = (end - start) / 1000000 // ms
        utils.msg(0,
            fmt.sprintf("latency: %d ms\n",latency)
        )
    }
    if eng.exit_code != 0 {
        os.exit(eng.exit_code)
    }
}
