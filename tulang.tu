use fmt
use os 
use std
use compiler.utils
use compiler.compile
use compiler.parser
use asmer.asm
use linker.link 
//TODO: set by compiler
root = "/usr/local/lib"

class Compiler {
    // origin file
    code_files = []
    scan_dirs  = []
    // need asm compile and linker to generate executable file
    flag_run  = false
    // pass args to binary executor
    args = []
    // compiler || asmer || linker  
    // default compiler
    flag_type = "compiler"
    flag_gcc  = false
    //default executeable name
    out       = "a.out"
}
Compiler::print_help(){
    fmt.println("usage: ./tu [options|file.tu...|dir]\n" +
            "  run          编译成汇编后进行链接生成二进制可执行文件直接运行\n" +
            "  -s  *.tu|dir 编译为tulang代码为linux-amd64汇编文件\n" +
            "  -c  *.s |dir 编译汇编为elf&pecoff跨平台可重定向文件\n" +
            "  -o  *.o |dir 链接elf&pecofff可重定向文件生成最终执行程序\n" +
            "  -d           开启trace日志打印编译详细过程\n" +
            "  -gcc         基于gcc链接生成可执行程序\n" +
            "  -g           编译tu文件时带上debug段信息,支持栈回溯\n" +
            "  -nostd       不编译runtime&std相关内置库代码\n"
    )
}
Compiler::commadparse(){
    i = 0
    while i < std.len(os.argv())  {
        match os.argv()[i] {
            "run" : {
                this.type = "compiler" 
                this.flag_run = true
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
            "-g"  : compile.debug    = true
            "-nostd" : compile.nostd = true
            "-gcc"   : this.flag_gcc = true
            _     : utils.error("unkown option[%s]",os.argv()[i])
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
    if !this.flag_gcc {
        compile.nostd = true
    }
    compile.genast(file)
    compile.editast()
    compile.compile()
    utils.msg(30,"Compiler generate all Passed")
    if this.flag_run {
        //By Gcc Link
        if this.flag_gcc {
            compile.link()
            os.shell("rm *.s")
            os.shell("rm *.o")
            os.shell("chmod 777 a.out")
        }else {
        //Self Asmer && Linker
            this.code_files = []
            this.scandir(".",".s")
            this.asmer()
            this.code_files = []
            this.scandir(".",".o")
            this.scandir(root + "/colib/",".o")
            this.linker()
            os.shell("rm *.o *.s")
        }
        os.shell("chmod 777 a.out")
        // args = "./a.out"
        // os.shell(args)
    }
    utils.msg2(100,"Finished",fmt.sprintf(
        "%s target(a.out)",file
    ))
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
    eng = new Compiler()
    if os.argc() < 2 {
        return eng.print_help() 
    }
    os.set_stack(10.(i8))
    eng.commadparse() // handle options
    eng.compile()
}
