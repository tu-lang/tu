use fmt
use os 
use std
use compiler.utils
use compiler.compile
use compiler.parser
use asmer.asm
use linker.link 
use runtime
//TODO: set by compiler
root = "/usr/local/lib"
version = "1.0.0"
printlat = false

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
    // compiler || asmer || linker  
    // default compiler
    type = "compiler"
    flag_gcc  = false
    //default executeable name
    out       = "a.out"
    // workdir: default TMPDIR/tu-build-*; --workdir-cwd or --workdir DIR
    workdir_cwd = false
    workdir_explicit = ""
    // Keep .s/.o after build when --work is set
    flag_work = false
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
        "  -g                         带 debug 段（支持栈回溯）\n" +
        "  -gcc                       使用 gcc 链接\n" +
        "  -strip-pcln-file           pclntab 不写入文件名\n" +
        "  -std                       同时编译 runtime/std 内置库\n" +
        "  --workdir DIR              中间产物写到 DIR（.s/.o/a.out）\n" +
        "  --workdir-cwd              中间产物写当前目录（旧行为）\n" +
        "  --work                     保留中间产物\n" +
        "  -v                         打印版本\n" +
        "\n" +
        "Default workdir: $TMPDIR/tu-build-<stem>-...\n"
    )
}
Compiler::commadparse(){
    i = 0
    while i < std.len(os.argv())  {
        match os.argv()[i] {
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
                asm.trace     = true  
                link.trace    = true
            }
            "-g"   : compile.debug    = true
            "-std" : compile.nostd = false
            "-gcc" : this.flag_gcc = true
            "-strip-pcln-file" : {
                link.strip_pcln_file = 1
            }
            "-lat" : printlat = true
            "--workdir-cwd" : this.workdir_cwd = true
            "--work" : this.flag_work = true
            "--workdir" : {
                this.workdir_explicit = os.argv()[i + 1]
                i += 1
            }
            "-v"   : {
                fmt.printf(
                    "tu-lang version: %s\n" +
                    "Target         : x86_64 linux\n",
                    version
                )
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
    fd = std.opendir(dir)
    loop {
        file = fd.readdir()
        if !file break
        if !file.isFile() continue
        filename = file.path
        ext = string.sub(filename,std.len(filename) - 2)
        if ext == dstext {
            utils.debugf("main.scandir: add %s ",file.path)
            this.code_files[] = file.path
        }
    }
}
Compiler::compiler(file){
    utils.debug("main.compiler")
    utils.msg2(10,"Compiling",fmt.sprintf(
        "%s v0.0.0",file
    ))
    if compile.nostd && !this.flag_gcc {
        compile.nostd = true
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
    if this.flag_link {
        //By Gcc Link
        if this.flag_gcc {
            compile.gcclink()
            if !this.flag_work {
                os.shell("rm -f '" + wd + "'/*.s")
            }
            os.shell("chmod 777 '" + utils.pathInWorkdir("a.out") + "'")
        }else {
        //Self Asmer && Linker
            this.code_files = []
            this.scandir(wd,".s")
            if !compile.nostd 
                this.scandir(root + "/coasm/",".s")
            this.asmer()

            this.code_files = []
            this.scandir(wd,".o")
            if compile.nostd 
                this.scandir(root + "/colib/",".o")
            this.out = utils.pathInWorkdir("a.out")
            this.linker()
            if !this.flag_work {
                os.shell("rm -f '" + wd + "'/*.o '" + wd + "'/*.s")
            }
        }
        os.shell("chmod 777 '" + utils.pathInWorkdir("a.out") + "'")
        if this.flag_work {
            fmt.printf("[tu] work: keeping %s\n", wd)
        }
    }
    exe = utils.pathInWorkdir("a.out")
    utils.msg2(100,"Finished",fmt.sprintf(
        "%s target(%s)",file, exe
    ))
    // `tu run`: execute linked binary
    if this.flag_exec {
        cmd = "'" + exe + "'"
        for a : this.args {
            cmd += " '" + a + "'"
        }
        fmt.println(cmd)
        os.shell(cmd)
    }
}
Compiler::asmer(){
    total = std.len(this.code_files)
    if total <= 0 utils.error("please provide at lease one .o file")
    //start gen
    i = 1
    for f : this.code_files {
	    utils.smsg("[ " + i + "/" + total +"]","Compiling asm file " + f)
        eng<asm.Asmer> = new asm.Asmer(f)
        eng.execute()
        eng.close()
	    utils.smsg("[ " + i + "/" + total +"]",
            fmt.sprintf("Generate %s Passed" ,eng.parser.outname)
        )
        i += 1
    }
    utils.msg(100,"Aasmer generate all Passed")
}
Compiler::linker(){
    linker = new link.Linker()
    total = std.len(this.code_files)
    if total <= 0 utils.error("please provide at lease one .o file")

    // a.out 默认落在首个 .o 同目录（与母版 tul 一致）
    if this.out == "a.out" && total > 0 {
        this.out = utils.path_join(utils.path_dirname(this.code_files[0]), "a.out")
    }
    fmt.printf("[tu] outfile: %s\n", this.out)

    i = 1
    for f : this.code_files {
	    utils.smsg("[ " + i + "/" + total +"]","Reading elf object info " + f)
        linker.addElf(f)
        i += 1
    }
    if !linker.link(this.out) {
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
    start<i64> = std.ntime()
    eng = new Compiler()
    if os.argc() < 1 {
        return eng.print_help() 
    }
    os.set_stack(10.(i8))
    eng.commadparse() // handle options
    eng.compile()

    end<i64> = std.ntime()
    if printlat {
        latency<i64> = end - start
        latency /= 1000000 // ms
        utils.msg(0,
            fmt.sprintf("latency: %d ms\n",int(latency))
        )
    }
}
