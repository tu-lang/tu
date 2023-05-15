use fmt
use os 
use std
use compiler.utils
use compiler.compile
use compiler.parser

# origin file
code_file = ""

# need asm compile and linker to generate executable file
run  = false

# pass args to binary executor
args = []

func print_help(){
    fmt.println("usage: ./toc [options|file.tu...]\n" +
            "  run      编译成汇编后进行链接生成二进制可执行文件直接运行\n" +
            "  -s       编译为linux-amd64汇编文件\n"
    )
}

//TODO: support llvm codgen
func llvmgen(){
    //c = new Compiler()
    //c.generate()
    //c.outIR()
    //c.genBinary()
}
func compile(){
    utils.debug("main.compile")
    utils.msg2(10,"Compiling",fmt.sprintf(
        "%s v0.0.0",code_file
    ))
    compile.genast(code_file)
    compile.editast()
    compile.compile()
    utils.msg2(100,"Finished",fmt.sprintf(
        "%s target(a.out)",code_file
    ))
    if run {
        compile.gcclink() # link automaticlly
        os.shell("rm *.s")
        args = "./a.out"
        os.shell(args)
    }
}
func debug(){
    p = new parser.Parser()
    p.print()
}

func main() {
    if os.argc() < 2 return print_help() 
    code_file = ""
    os.set_stack(10.(i8))

    i = 0
    while i < std.len(os.argv())  {
        match os.argv()[i] {
            "run" : {
                code_file = os.argv()[i + 1]
                i += 1
                run = true
            }
            "-d"  : compile.trace = true          # debug mode
            "-g"  : compile.debug    = true
            "-og" : compile.sdebug   = true
            "-s"  : {
                code_file = os.argv()[i + 1]
                i += 1
            }
            "-nostd" : compile.nostd = true
            _     : args[] = os.argv()[i]
        }
        i += 1
    }
    if code_file != "" {
        return compile()
    }
}
