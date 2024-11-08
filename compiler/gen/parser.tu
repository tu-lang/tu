use compiler.compile
use std
use compiler.parser
use compiler.utils

rd_done = false

parser.Parser::registeDefault(){
    if rd_done return true

    if this.pkg.package == "runtime" {
        compile.writeln("    .global runtime_default_virfuture")
        compile.writeln("runtime_default_virfuture:")
        compile.writeln("   .quad 0")
        compile.writeln("   .quad 0")
        compile.writeln("   .quad 0")
        compile.writeln("   .quad 0")
        compile.writeln("   .quad 1")
        compile.writeln("   .quad 0")
        compile.writeln("   .long 0")
        compile.writeln("   .long 0") 
        compile.writeln("   .quad 0")
        rd_done = true
    }
}

parser.Parser::compile()
{    
    utils.debug("gen.parser.Parser::compile()")
    asm = new std.File(this.asmfile,"w")
	if asm == null || !asm.IsOpen() {
        this.panic(
            "genrate assembly file failed package:%s file:%s",
            this.pkg.package,this.filename
        )
	}
    //asm file generate start
    compile.out = asm
    compile.currentParser = this
    if compile.debug
        compile.writeln("    .file %d \"%s\"",this.fileno,this.filepath)

    compile.writeln(".data")
    compile.funcs_offsets()
    compile.registerVars()
    compile.registerStrings()
    compile.registerObjects()
    compile.registerFutures()
    this.registeDefault()

    compile.writeln(".text")
    
    compile.registerFuncs()
    compile.currentParser = null

    asm.Close()
    compile.out = null

}